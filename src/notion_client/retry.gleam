//// Retry policy mirroring the Notion JS SDK behaviour.
////
//// Pure: takes a sender, a sleep function and a jitter function as
//// arguments so tests can drive it deterministically. The real
//// `notion_client.request` wires the production sender (`gleam/httpc`)
//// plus `gleam/erlang/process.sleep` and `gleam/int.random` for jitter.
////
//// Retried responses (matching JS SDK):
////   * any 429 — regardless of HTTP method
////   * 500 / 503 on `GET` and `DELETE` only (idempotent verbs)
////   * `httpc.ResponseTimeout` transport failures
////
//// Backoff: `min(base * 2^attempt, max) + jitter(0..delay)`. When the
//// server returns a `Retry-After` header (in seconds), we honour it and
//// skip the computed backoff for that attempt.

import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/httpc
import gleam/int
import gleam/result

pub type RetryConfig {
  NoRetry
  Backoff(max_attempts: Int, base_delay_ms: Int, max_delay_ms: Int)
}

pub type RawResult =
  Result(Response(BitArray), httpc.HttpError)

pub type Sender =
  fn(Request(BitArray)) -> RawResult

pub type Sleeper =
  fn(Int) -> Nil

/// Pure jitter callback. Receives the computed backoff delay (ms) and
/// returns an extra delay (ms) to add. Pass `fn(_) { 0 }` for no jitter.
pub type Jitter =
  fn(Int) -> Int

/// Observer fired right before each retry sleep. Arguments are the
/// 1-based attempt number that is about to be retried and the delay
/// (ms) that will be slept. Pass `fn(_, _) { Nil }` to ignore.
pub type Observer =
  fn(Int, Int) -> Nil

pub fn run(
  config: RetryConfig,
  sender: Sender,
  sleep: Sleeper,
  jitter: Jitter,
  on_retry: Observer,
  req: Request(BitArray),
) -> RawResult {
  case config {
    NoRetry -> sender(req)
    Backoff(max_attempts, base, cap) ->
      attempt(sender, sleep, jitter, on_retry, req, max_attempts, base, cap, 0)
  }
}

fn attempt(
  sender: Sender,
  sleep: Sleeper,
  jitter: Jitter,
  on_retry: Observer,
  req: Request(BitArray),
  max_attempts: Int,
  base: Int,
  cap: Int,
  n: Int,
) -> RawResult {
  let res = sender(req)
  case should_retry(res, req.method) {
    False -> res
    True ->
      case n + 1 >= max_attempts {
        True -> res
        False -> {
          let delay = compute_delay(res, base, cap, jitter, n)
          on_retry(n + 1, delay)
          sleep(delay)
          attempt(
            sender,
            sleep,
            jitter,
            on_retry,
            req,
            max_attempts,
            base,
            cap,
            n + 1,
          )
        }
      }
  }
}

pub fn should_retry(res: RawResult, method: http.Method) -> Bool {
  case res {
    Error(httpc.ResponseTimeout) -> True
    Error(_) -> False
    Ok(resp) ->
      case resp.status {
        429 -> True
        500 | 503 ->
          case method {
            http.Get | http.Delete -> True
            _ -> False
          }
        _ -> False
      }
  }
}

pub fn compute_delay(
  res: RawResult,
  base: Int,
  cap: Int,
  jitter: Jitter,
  attempt: Int,
) -> Int {
  case res {
    Ok(resp) ->
      case retry_after_ms(resp) {
        Ok(ms) -> ms
        Error(_) -> backoff(base, cap, jitter, attempt)
      }
    Error(_) -> backoff(base, cap, jitter, attempt)
  }
}

fn backoff(base: Int, cap: Int, jitter: Jitter, attempt: Int) -> Int {
  let raw = base * pow2(attempt)
  let capped = int.min(raw, cap)
  capped + jitter(capped)
}

fn pow2(n: Int) -> Int {
  case n {
    n if n <= 0 -> 1
    n -> 2 * pow2(n - 1)
  }
}

fn retry_after_ms(resp: Response(BitArray)) -> Result(Int, Nil) {
  response.get_header(resp, "retry-after")
  |> result.try(int.parse)
  |> result.map(fn(seconds) { seconds * 1000 })
}

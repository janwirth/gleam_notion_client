//// Unit tests for the retry policy. Drives `retry.run` with a fake
//// stateful sender and a fake sleeper so we can assert exact behaviour
//// without sleeping or hitting the network.

import gleam/dynamic.{type Dynamic}
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/httpc
import gleeunit
import notion_client/retry.{Backoff, NoRetry}

pub fn main() -> Nil {
  gleeunit.main()
}

@external(erlang, "erlang", "put")
fn pdict_put(key: a, value: b) -> Dynamic

@external(erlang, "erlang", "get")
fn pdict_get(key: a) -> Dynamic

@external(erlang, "erlang", "erase")
fn pdict_erase(key: a) -> Dynamic

type ResponseScript =
  List(Result(Response(BitArray), httpc.HttpError))

@external(erlang, "test_helpers", "as_response_script")
fn as_response_script(d: Dynamic) -> ResponseScript

@external(erlang, "test_helpers", "as_int_list")
fn as_int_list(d: Dynamic) -> List(Int)

fn install_responses(rs: ResponseScript) -> Nil {
  pdict_put("rt_responses", rs)
  pdict_put("rt_sleeps", [])
  pdict_put("rt_call_count", 0)
  Nil
}

fn pop_response() -> Result(Response(BitArray), httpc.HttpError) {
  let count_dyn = pdict_get("rt_call_count")
  let count = case dynamic.classify(count_dyn) == "Int" {
    True -> unsafe_to_int(count_dyn)
    False -> 0
  }
  pdict_put("rt_call_count", count + 1)
  let queue = as_response_script(pdict_get("rt_responses"))
  case queue {
    [head, ..rest] -> {
      pdict_put("rt_responses", rest)
      head
    }
    [] -> panic as "fake sender exhausted"
  }
}

@external(erlang, "test_helpers", "to_int")
fn unsafe_to_int(d: Dynamic) -> Int

fn record_sleep(ms: Int) -> Nil {
  let prev = as_int_list(pdict_get("rt_sleeps"))
  pdict_put("rt_sleeps", [ms, ..prev])
  Nil
}

fn no_jitter(_: Int) -> Int {
  0
}

fn sleeps() -> List(Int) {
  as_int_list(pdict_get("rt_sleeps"))
}

fn call_count() -> Int {
  unsafe_to_int(pdict_get("rt_call_count"))
}

fn cleanup() -> Nil {
  pdict_erase("rt_responses")
  pdict_erase("rt_sleeps")
  pdict_erase("rt_call_count")
  Nil
}

fn ok_response(status: Int) -> Result(Response(BitArray), httpc.HttpError) {
  Ok(response.Response(status: status, headers: [], body: <<>>))
}

fn ok_response_with(
  status: Int,
  headers: List(#(String, String)),
) -> Result(Response(BitArray), httpc.HttpError) {
  Ok(response.Response(status: status, headers: headers, body: <<>>))
}

fn req(method: http.Method) -> Request(BitArray) {
  request.new()
  |> request.set_method(method)
  |> request.set_body(<<>>)
}

pub fn no_retry_calls_sender_once_test() {
  install_responses([ok_response(500)])
  let res =
    retry.run(
      NoRetry,
      fn(_) { pop_response() },
      record_sleep,
      no_jitter,
      fn(_, _) { Nil },
      req(http.Get),
    )
  assert call_count() == 1
  assert sleeps() == []
  assert res == ok_response(500)
  cleanup()
}

pub fn retries_429_until_success_test() {
  install_responses([ok_response(429), ok_response(429), ok_response(200)])
  let res =
    retry.run(
      Backoff(max_attempts: 5, base_delay_ms: 100, max_delay_ms: 1000),
      fn(_) { pop_response() },
      record_sleep,
      no_jitter,
      fn(_, _) { Nil },
      req(http.Post),
    )
  assert call_count() == 3
  assert sleeps() == [200, 100]
  assert res == ok_response(200)
  cleanup()
}

pub fn retries_500_only_on_idempotent_methods_test() {
  install_responses([ok_response(500)])
  let res_post =
    retry.run(
      Backoff(max_attempts: 3, base_delay_ms: 50, max_delay_ms: 500),
      fn(_) { pop_response() },
      record_sleep,
      no_jitter,
      fn(_, _) { Nil },
      req(http.Post),
    )
  assert call_count() == 1
  assert sleeps() == []
  assert res_post == ok_response(500)
  cleanup()

  install_responses([ok_response(500), ok_response(200)])
  let res_get =
    retry.run(
      Backoff(max_attempts: 3, base_delay_ms: 50, max_delay_ms: 500),
      fn(_) { pop_response() },
      record_sleep,
      no_jitter,
      fn(_, _) { Nil },
      req(http.Get),
    )
  assert call_count() == 2
  assert sleeps() == [50]
  assert res_get == ok_response(200)
  cleanup()
}

pub fn honors_retry_after_header_test() {
  install_responses([
    ok_response_with(429, [#("retry-after", "2")]),
    ok_response(200),
  ])
  let res =
    retry.run(
      Backoff(max_attempts: 3, base_delay_ms: 100, max_delay_ms: 10_000),
      fn(_) { pop_response() },
      record_sleep,
      no_jitter,
      fn(_, _) { Nil },
      req(http.Get),
    )
  assert call_count() == 2
  assert sleeps() == [2000]
  assert res == ok_response(200)
  cleanup()
}

pub fn returns_last_error_when_attempts_exhausted_test() {
  install_responses([ok_response(429), ok_response(429), ok_response(429)])
  let res =
    retry.run(
      Backoff(max_attempts: 3, base_delay_ms: 10, max_delay_ms: 100),
      fn(_) { pop_response() },
      record_sleep,
      no_jitter,
      fn(_, _) { Nil },
      req(http.Get),
    )
  assert call_count() == 3
  assert sleeps() == [20, 10]
  assert res == ok_response(429)
  cleanup()
}

pub fn retries_response_timeout_transport_error_test() {
  install_responses([Error(httpc.ResponseTimeout), ok_response(200)])
  let res =
    retry.run(
      Backoff(max_attempts: 3, base_delay_ms: 10, max_delay_ms: 100),
      fn(_) { pop_response() },
      record_sleep,
      no_jitter,
      fn(_, _) { Nil },
      req(http.Get),
    )
  assert call_count() == 2
  assert sleeps() == [10]
  assert res == ok_response(200)
  cleanup()
}

pub fn caps_backoff_at_max_delay_test() {
  install_responses([
    ok_response(429),
    ok_response(429),
    ok_response(429),
    ok_response(429),
    ok_response(200),
  ])
  let res =
    retry.run(
      Backoff(max_attempts: 6, base_delay_ms: 100, max_delay_ms: 300),
      fn(_) { pop_response() },
      record_sleep,
      no_jitter,
      fn(_, _) { Nil },
      req(http.Get),
    )
  assert call_count() == 5
  // attempts 0..3 → raw delays 100,200,400,800; capped at 300 from idx 2 onwards
  // sleeps recorded reverse order: [300, 300, 200, 100]
  assert sleeps() == [300, 300, 200, 100]
  assert res == ok_response(200)
  cleanup()
}

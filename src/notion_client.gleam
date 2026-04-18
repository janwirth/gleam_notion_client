//// Notion API client (BEAM only).
////
//// This module owns the public surface: the [`Client`](#Client) record,
//// the [`new`](#new) constructor, and a low-level [`send`](#send)
//// transport that runs requests built by `notion_client/operations`
//// through `gleam/httpc`.
////
//// Generated request builders + response decoders live in
//// `notion_client/operations` and `notion_client/schema`. Run
//// `bash scripts/regenerate.sh` to refresh them.
////
//// The block below the marker is overwritten by `oas/generator.build`.
//// On BEAM we don't ship the generated facade (it depends on midas /
//// javascript), so `scripts/regenerate.sh` truncates everything below
//// the marker after each run.

import gleam/erlang/process
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/httpc
import gleam/int
import gleam/option
import gleam/uri
import notion_client/error.{
  type NotionError, ClientError, RequestTimeout, ResponseBodyError,
  UnknownHttpResponseError,
}
import notion_client/retry.{type RetryConfig, Backoff}

pub const default_base_url: String = "https://api.notion.com"

pub const default_notion_version: String = "2022-06-28"

pub const default_timeout_ms: Int = 30_000

pub type LogLevel {
  Silent
  Info
  Debug
}

pub type Logger =
  fn(String) -> Nil

pub type Client {
  Client(
    auth: String,
    base_url: String,
    timeout_ms: Int,
    notion_version: String,
    log_level: LogLevel,
    logger: Logger,
    retry: RetryConfig,
  )
}

pub const default_retry: RetryConfig = Backoff(
  max_attempts: 3,
  base_delay_ms: 250,
  max_delay_ms: 5000,
)

/// Construct a `Client` with sensible defaults. `auth` is the Notion
/// integration token (sent as `Authorization: Bearer <auth>`).
pub fn new(auth: String) -> Client {
  Client(
    auth: auth,
    base_url: default_base_url,
    timeout_ms: default_timeout_ms,
    notion_version: default_notion_version,
    log_level: Silent,
    logger: fn(_msg) { Nil },
    retry: default_retry,
  )
}

/// Build the base request consumed by `notion_client/operations.*_request`.
/// Injects `Authorization`, `Notion-Version`, `Content-Type` and `Accept`
/// headers, plus the scheme/host/port parsed from `client.base_url`.
pub fn base_request(client: Client) -> Request(BitArray) {
  let assert Ok(parsed) = uri.parse(client.base_url)
  let scheme = case parsed.scheme {
    option.Some("http") -> http.Http
    _ -> http.Https
  }
  let host = case parsed.host {
    option.Some(h) -> h
    option.None -> "api.notion.com"
  }
  let req =
    request.new()
    |> request.set_scheme(scheme)
    |> request.set_host(host)
    |> request.set_body(<<>>)
    |> request.prepend_header("authorization", "Bearer " <> client.auth)
    |> request.prepend_header("notion-version", client.notion_version)
    |> request.prepend_header("content-type", "application/json")
    |> request.prepend_header("accept", "application/json")
  case parsed.port {
    option.Some(port) -> request.set_port(req, port)
    option.None -> req
  }
}

/// Send a fully composed request through `gleam/httpc`, honouring the
/// client's `timeout_ms`. Retries are applied in task 07.
pub fn send(
  client: Client,
  req: Request(BitArray),
) -> Result(Response(BitArray), httpc.HttpError) {
  httpc.configure()
  |> httpc.timeout(client.timeout_ms)
  |> httpc.dispatch_bits(req)
}

/// Typed transport: same wire call as [`send`](#send) but applies the
/// client's retry policy and classifies every failure (transport or
/// non-2xx response) into a
/// [`NotionError`](notion_client/error.html#NotionError) so callers
/// never need to handle `httpc.HttpError` or raw status codes.
pub fn request(
  client: Client,
  req: Request(BitArray),
) -> Result(Response(BitArray), NotionError) {
  let sender = fn(r) { send(client, r) }
  retry.run(client.retry, sender, process.sleep, int.random, req)
  |> classify
}

fn classify(
  res: Result(Response(BitArray), httpc.HttpError),
) -> Result(Response(BitArray), NotionError) {
  case res {
    Error(httpc.ResponseTimeout) -> Error(ClientError(RequestTimeout))
    Error(httpc.InvalidUtf8Response) ->
      Error(ClientError(ResponseBodyError("invalid utf8 in response body")))
    Error(httpc.FailedToConnect(_, _)) ->
      Error(ClientError(UnknownHttpResponseError("failed to connect")))
    Ok(resp) ->
      case resp.status {
        s if s >= 200 && s < 300 -> Ok(resp)
        s -> Error(error.parse_api_error(resp.body, s))
      }
  }
}
// GENERATED -------------

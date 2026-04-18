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
import notion_client/logging.{type Logger}
import notion_client/retry.{type RetryConfig, Backoff}

pub const default_base_url: String = "https://api.notion.com"

pub const default_notion_version: String = "2022-06-28"

pub const default_timeout_ms: Int = 30_000

pub type Client {
  Client(
    auth: String,
    base_url: String,
    timeout_ms: Int,
    notion_version: String,
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
/// integration token (sent as `Authorization: Bearer <auth>`). The
/// default logger filters at `Warn` and writes to stderr; swap it for
/// [`logging.silent_logger`](notion_client/logging.html#silent_logger)
/// or your own pipeline by replacing the `logger` field.
pub fn new(auth: String) -> Client {
  Client(
    auth: auth,
    base_url: default_base_url,
    timeout_ms: default_timeout_ms,
    notion_version: default_notion_version,
    logger: logging.default_logger(),
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
///
/// Emits four logging events (gated by the client's `logger`):
/// `request.start` (Debug), `request.retry` (Info, one per retry),
/// `request.complete` (Debug, on 2xx) and `request.error` (Warn).
pub fn request(
  client: Client,
  req: Request(BitArray),
) -> Result(Response(BitArray), NotionError) {
  let method = method_string(req.method)
  let path = req.path
  logging.log(client.logger, logging.Debug, "request.start", [
    #("method", method),
    #("path", path),
  ])
  let sender = fn(r) { send(client, r) }
  let on_retry = fn(attempt, delay_ms) {
    logging.log(client.logger, logging.Info, "request.retry", [
      #("attempt", int.to_string(attempt)),
      #("delay_ms", int.to_string(delay_ms)),
      #("path", path),
    ])
  }
  let raw =
    retry.run(client.retry, sender, process.sleep, int.random, on_retry, req)
  let result = classify(raw)
  case result {
    Ok(resp) ->
      logging.log(client.logger, logging.Debug, "request.complete", [
        #("path", path),
        #("status", int.to_string(resp.status)),
      ])
    Error(err) ->
      logging.log(client.logger, logging.Warn, "request.error", [
        #("path", path),
        #("error", error_label(err)),
      ])
  }
  result
}

fn method_string(method: http.Method) -> String {
  case method {
    http.Get -> "GET"
    http.Post -> "POST"
    http.Put -> "PUT"
    http.Patch -> "PATCH"
    http.Delete -> "DELETE"
    http.Head -> "HEAD"
    http.Options -> "OPTIONS"
    http.Connect -> "CONNECT"
    http.Trace -> "TRACE"
    http.Other(s) -> s
  }
}

fn error_label(err: NotionError) -> String {
  case err {
    error.ApiResponseError(code: _, status: status, message: _) ->
      "api:" <> int.to_string(status)
    error.ClientError(code: code) -> "client:" <> client_code_label(code)
  }
}

fn client_code_label(code: error.ClientErrorCode) -> String {
  case code {
    RequestTimeout -> "timeout"
    ResponseBodyError(_) -> "response_body"
    UnknownHttpResponseError(_) -> "transport"
  }
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

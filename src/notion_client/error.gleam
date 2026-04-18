//// Typed errors mirroring the Notion JavaScript SDK's
//// `NotionClientError` / `APIResponseError` taxonomy.
////
//// `notion_client.request` (the typed transport) classifies every
//// non-2xx response and every transport failure into one of these
//// variants — callers never see raw `httpc.HttpError` or stringly-
//// typed status codes.

import gleam/bit_array
import gleam/dynamic/decode
import gleam/json
import gleam/result

/// Notion API error codes. List sourced from the JS SDK's
/// `APIErrorCode` enum (https://github.com/makenotion/notion-sdk-js)
/// plus the additional codes the public docs return as of 2026-04.
/// `UnknownErrorCode(String)` keeps forwards compatibility when Notion
/// adds a new code we have not enumerated yet.
pub type ApiErrorCode {
  Unauthorized
  RestrictedResource
  ObjectNotFound
  RateLimited
  InvalidJson
  InvalidRequestUrl
  InvalidRequest
  InvalidGrant
  ValidationError
  MissingVersion
  ConflictError
  InternalServerError
  ServiceUnavailable
  DatabaseConnectionUnavailable
  GatewayTimeout
  UnknownErrorCode(String)
}

/// Errors that originate inside the client (transport, parsing, etc).
/// Maps onto the JS SDK's `ClientErrorCode` set.
pub type ClientErrorCode {
  RequestTimeout
  ResponseBodyError(String)
  UnknownHttpResponseError(String)
}

/// Top-level error returned from `notion_client.request`.
pub type NotionError {
  /// Notion responded with a non-2xx status and a parsable error body.
  /// Fields: code, HTTP status, raw `message` from the body.
  ApiResponseError(code: ApiErrorCode, status: Int, message: String)

  /// Failure originating in the client (transport, decode, timeout, …).
  ClientError(code: ClientErrorCode)
}

/// `True` when the result carries any [`NotionError`](#NotionError).
/// Mirrors `isNotionClientError` in the JS SDK.
pub fn is_notion_client_error(r: Result(a, NotionError)) -> Bool {
  result.is_error(r)
}

/// Parse a Notion error response body. Falls back to
/// `ApiResponseError(UnknownErrorCode("decode_failed"), status, raw)`
/// when the body is not the expected `{object: error, code, message}`
/// shape — keeps an `ApiResponseError` for the caller instead of
/// silently dropping context.
pub fn parse_api_error(body: BitArray, status: Int) -> NotionError {
  let decoder = {
    use code <- decode.field("code", decode.string)
    use message <- decode.field("message", decode.string)
    decode.success(#(code, message))
  }
  case json.parse_bits(body, decoder) {
    Ok(#(code, message)) ->
      ApiResponseError(api_error_code_from_string(code), status, message)
    Error(_) -> {
      let raw = case bit_array.to_string(body) {
        Ok(s) -> s
        Error(_) -> "<non-utf8 body>"
      }
      ApiResponseError(UnknownErrorCode("decode_failed"), status, raw)
    }
  }
}

/// Map Notion's `code` string to an [`ApiErrorCode`](#ApiErrorCode).
pub fn api_error_code_from_string(code: String) -> ApiErrorCode {
  case code {
    "unauthorized" -> Unauthorized
    "restricted_resource" -> RestrictedResource
    "object_not_found" -> ObjectNotFound
    "rate_limited" -> RateLimited
    "invalid_json" -> InvalidJson
    "invalid_request_url" -> InvalidRequestUrl
    "invalid_request" -> InvalidRequest
    "invalid_grant" -> InvalidGrant
    "validation_error" -> ValidationError
    "missing_version" -> MissingVersion
    "conflict_error" -> ConflictError
    "internal_server_error" -> InternalServerError
    "service_unavailable" -> ServiceUnavailable
    "database_connection_unavailable" -> DatabaseConnectionUnavailable
    "gateway_timeout" -> GatewayTimeout
    other -> UnknownErrorCode(other)
  }
}

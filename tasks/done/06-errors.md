# Error types

**Phase:** 2 — Error Handling
**Depends on:** 05-client-record

## Goal
Unified `NotionError` with server/client code enums mirroring JS SDK.

## Steps
- [x] `src/notion_client/error.gleam`:
  - `NotionError = ApiResponseError(ApiErrorCode, Int, String) | ClientError(ClientErrorCode)`
  - `ApiErrorCode` covers JS SDK's `APIErrorCode` enum + `UnknownErrorCode(String)` fallback
  - `ClientErrorCode = RequestTimeout | ResponseBodyError(String) | UnknownHttpResponseError(String)`
- [x] `is_notion_client_error(Result) -> Bool`
- [x] Parse Notion error JSON body → `ApiResponseError`
- [x] Wire into request runner (`notion_client.request/2`)

## Done when
4xx/5xx responses decode to typed `NotionError`, not raw strings.

## Notes
- Two-layer taxonomy mirrors JS SDK: `ApiResponseError` (server returned a
  parsable error envelope) vs `ClientError` (transport failure, body decode
  problem, etc).
- `ApiErrorCode` enumerates every code in the JS SDK's `APIErrorCode` enum
  plus the extras Notion's public docs list (rate_limited,
  database_connection_unavailable, gateway_timeout). Unknown codes fall
  through to `UnknownErrorCode(String)` so we stay forwards-compatible.
- `parse_api_error` falls back to
  `ApiResponseError(UnknownErrorCode("decode_failed"), status, raw_body)` on
  malformed JSON instead of dropping the response — caller still sees status
  + raw body for debugging.
- New `notion_client.request/2` is the typed transport; `notion_client.send/2`
  remains as the raw escape hatch (still useful for ad-hoc wire debugging).
- Tests in `test/notion_client_test.gleam` cover all three branches:
  enumerated code, unknown code, garbage body. Run with `gleam test`.

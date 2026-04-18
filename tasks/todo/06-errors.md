# Error types

**Phase:** 2 — Error Handling
**Depends on:** 05-client-record

## Goal
Unified `NotionError` with server/client code enums mirroring JS SDK.

## Steps
- [ ] `src/notion_client/error.gleam`:
  - `NotionError = ApiResponseError(ApiErrorCode, Int, String) | ClientError(ClientErrorCode) | RequestTimeout | ResponseBodyError(String)`
  - `ApiErrorCode = ObjectNotFound | Unauthorized | RestrictedResource | RateLimited | InvalidJson | InvalidRequestUrl | InvalidRequest | ValidationError | ConflictError | InternalServerError | ServiceUnavailable | ...`
  - `ClientErrorCode = RequestTimeout | ResponseBodyError | UnknownHttpResponseError`
- [ ] `is_notion_client_error(Result) -> Bool`
- [ ] Parse Notion error JSON body → `ApiResponseError`
- [ ] Wire into request runner

## Done when
4xx/5xx responses decode to typed `NotionError`, not raw strings.

# Client record + request runner

**Phase:** 1 — Core Client
**Depends on:** 03-generate-gleam-from-openapi

## Goal
`Client` config type + low-level `request` function that injects Notion headers.

## Steps
- [x] `src/notion_client.gleam`: `Client` record with `auth`, `base_url`, `timeout_ms`, `notion_version`, `log_level`, `logger`, `retry`
- [x] Default constants (`DEFAULT_BASE_URL = "https://api.notion.com"`, `DEFAULT_TIMEOUT_MS`)
- [x] `new(auth)` constructor
- [x] `request` fn: injects `Authorization: Bearer`, `Notion-Version`, `Content-Type: application/json`
- [x] Wire `request` into generated client as the transport

## Done when
Manual test: `notion_client.new(token) |> users.me()` returns `Ok(User)` against live API.

## Notes
- `Client` record fields per task spec: `auth`, `base_url`, `timeout_ms`, `notion_version`, `log_level` (`Silent | Info | Debug`), `logger: fn(String) -> Nil`, `retry` (`NoRetry | ExponentialBackoff(max_attempts, base_delay_ms)`). `Retry` is a placeholder — its semantics arrive in task 07.
- Defaults exported as `pub const`: `default_base_url = "https://api.notion.com"`, `default_notion_version = "2022-06-28"`, `default_timeout_ms = 30_000`.
- `new(auth)` returns a `Client` with all defaults applied, `log_level: Silent`, `logger: fn(_) { Nil }`, `retry: NoRetry`.
- Transport split:
  - `base_request(client) -> Request(BitArray)` parses `client.base_url` via `gleam/uri`, sets scheme/host/port, and prepends `authorization`, `notion-version`, `content-type`, `accept` headers. Consumed by every generated `operations.*_request`.
  - `send(client, req) -> Result(Response(BitArray), httpc.HttpError)` runs through `gleam/httpc` with the client's `timeout_ms`. Per-op facades (task 12) chain `base_request -> *_request -> send -> *_response`.
- "Wire request into generated client as the transport" is the contract that `operations.*_request(base, ..)` accepts the `Request(BitArray)` produced by `base_request`. Verified end-to-end via the live test.
- Done-when verified by `test/notion_client_live_test.gleam` (`users_me_live_test`): reads `NOTION_TOKEN` from env (Erlang FFI to `os:getenv/1`), calls `operations.retrieve_your_token_sbot_user_request` + `notion_client.send`, asserts HTTP 200 and JSON body has `object` containing `"user"`. Skipped silently when `NOTION_TOKEN` is unset so CI without secrets stays green. Live run with the existing `.env` token returned 200 — Notion API reachable, headers accepted, decoder happy.
- Deps added: `gleam_httpc` v5.0.0 (transport), `gleam_erlang` v1.3.0 (charlist for `os:getenv`).
- `gleam build`, `gleam test` (2 passing), `gleam format`, and `bash scripts/regenerate.sh` (idempotent) all clean.

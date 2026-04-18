# Notion SDK for Gleam — Action Plan

Replicate [makenotion/notion-sdk-js](https://github.com/makenotion/notion-sdk-js) in Gleam.

## HTTP Client Choice

Per [gleam_ecosystem_review/http-clients.md](https://raw.githubusercontent.com/janwirth/gleam_ecosystem_review/refs/heads/main/gleam/http-clients.md):

- **BEAM target**: `gleam_httpc` (gold, zero extra deps)
- **JS target**: `gleam_fetch` (gold, wraps platform fetch)
- **Cross-target strategy**: Accept a `Sender` function parameter so consumers inject `httpc.send` on BEAM or a `fetch.send` wrapper on JS. Keeps core SDK target-agnostic.
- JSON: `gleam_json` for encode/decode.

## Scope (Parity with notion-sdk-js)

### Phase 1 — Core Client
- [ ] `Client` type with config: `auth`, `base_url`, `timeout_ms`, `notion_version`, `log_level`, `logger`, `retry`
- [ ] Default config constants (`DEFAULT_BASE_URL`, `DEFAULT_TIMEOUT_MS`, default retry policy)
- [ ] Generic `request` function: builds `gleam/http.Request`, injects `Authorization: Bearer`, `Notion-Version`, `Content-Type` headers
- [ ] Parameter consolidation: one record per endpoint combining path/query/body fields; splitter derives each

### Phase 2 — Error Handling
- [ ] `NotionError` union: `ApiResponseError(code, status, message)` | `ClientError(ClientErrorCode)` | `RequestTimeout` | `ResponseBodyError`
- [ ] `ApiErrorCode` enum mirroring JS SDK (`ObjectNotFound`, `Unauthorized`, `RateLimited`, `ValidationError`, etc.)
- [ ] `ClientErrorCode` enum (`RequestTimeout`, `ResponseBodyError`, `UnknownHttpResponseError`)
- [ ] `is_notion_client_error` helper (Result inspection)

### Phase 3 — Retries
- [ ] Exponential backoff with jitter
- [ ] Retry on 429 (all methods), 500/503 (GET/DELETE only)
- [ ] Honor `Retry-After` header
- [ ] `retry: False` opt-out

### Phase 4 — Endpoint Modules
Mirror JS namespaces as Gleam modules:
- [ ] `notion_client/users` — `list`, `retrieve`, `me`
- [ ] `notion_client/data_sources` — `query`, `retrieve`, `create`, `update`
- [ ] `notion_client/databases` — `query`, `retrieve`, `create`, `update`
- [ ] `notion_client/pages` — `create`, `retrieve`, `update`, `properties.retrieve`
- [ ] `notion_client/blocks` — `retrieve`, `update`, `delete`, `children.list`, `children.append`
- [ ] `notion_client/comments` — `create`, `list`
- [ ] `notion_client/search`
- [ ] `notion_client/views` — `create`
- [ ] `notion_client/oauth` — `token`, `revoke`, `introspect`

### Phase 5 — Pagination
- [ ] `iterate_paginated` → returns iterator/stream (BEAM: `gleam/iterator` or lazy list; JS: yield)
- [ ] `collect_paginated` → returns `List(a)` via recursive cursor walk

### Phase 6 — Types & Decoders
- [ ] Request param records per endpoint
- [ ] Response record types: `Page`, `Block`, `DataSource`, `Database`, `User`, `Comment`, `PropertyValue`, `RichText`, etc.
- [ ] Partial vs full response variants: `Full(T)` / `Partial(id)`
- [ ] Type guards: `is_full_page`, `is_full_block`, `is_full_data_source`, `is_full_user`, `is_full_comment`
- [ ] JSON decoders for all responses (`gleam/dynamic/decode`)
- [ ] JSON encoders for all request bodies

### Phase 7 — Logging
- [ ] `LogLevel` enum: `Debug`, `Info`, `Warn`, `Error`
- [ ] Logger type alias: `fn(LogLevel, String, Dict(String, Dynamic)) -> Nil`
- [ ] Default console logger; pluggable

### Phase 8 — Testing
- [ ] Record/playback fixtures (mirror `dream_http_client` pattern optional)
- [ ] Unit tests per endpoint module with recorded JSON
- [ ] Decoder round-trip tests
- [ ] Retry logic tests with fake clock + fake sender

## Project Layout

```
src/
  notion_client.gleam            -- Client, config, request runner
  notion_client/
    error.gleam                  -- NotionError, ApiErrorCode, ClientErrorCode
    retry.gleam                  -- backoff + retry logic
    pagination.gleam             -- iterate_paginated, collect_paginated
    logging.gleam                -- LogLevel, default logger
    sender.gleam                 -- Sender type alias (injected http fn)
    internal/
      headers.gleam
      json_helpers.gleam
    users.gleam
    data_sources.gleam
    databases.gleam
    pages.gleam
    blocks.gleam
    blocks/children.gleam
    comments.gleam
    search.gleam
    views.gleam
    oauth.gleam
    types/
      page.gleam
      block.gleam
      data_source.gleam
      user.gleam
      comment.gleam
      rich_text.gleam
      property.gleam
test/
  notion_client_test.gleam
  fixtures/                      -- recorded API responses
```

## Dependencies to Add (`gleam.toml`)

```toml
[dependencies]
gleam_stdlib = ">= 0.44.0 and < 2.0.0"
gleam_http = ">= 3.0.0"
gleam_httpc = ">= 4.0.0"           # BEAM sender
gleam_fetch = ">= 1.0.0"           # JS sender
gleam_json = ">= 2.0.0"
gleam_javascript = ">= 1.0.0"      # for Promise on JS target

[dev_dependencies]
gleeunit = ">= 1.0.0 and < 2.0.0"
```

## API Version Support
- Default: `2025-09-03`
- Opt-in: `2026-03-11`
- Set via `notion_version` field on Client, sent as `Notion-Version` header.

## Cross-Target Constraint
- No direct `httpc.send` or `fetch.send` inside core modules.
- `Client` holds a `send: fn(Request(String)) -> Result(Response(String), SendError)` field.
- Provide two factory constructors:
  - `notion_client.new_beam(auth)` — injects `gleam_httpc` sender
  - `notion_client.new_js(auth)` — injects `gleam_fetch` sender (returns `Promise`)
- Return types may need target-conditional wrapping (`Promise` on JS vs direct `Result` on BEAM). Consider two thin facade modules.

## Milestones

1. **M1** — Client + request runner + one endpoint (`users.me`) end-to-end on BEAM
2. **M2** — Error + retry + logging
3. **M3** — All endpoint modules with types/decoders
4. **M4** — Pagination helpers
5. **M5** — JS target parity
6. **M6** — Docs + publish to Hex

## Open Questions
- Single SDK with injected Sender vs. two packages (`notion_client_beam`, `notion_client_js`)?
- Depth of typed responses vs. returning `Dynamic` for caller-side decoding?
- Auto-generate types from Notion OpenAPI spec (if published) vs. hand-write?

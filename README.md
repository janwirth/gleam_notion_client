# notion_client

[![Package Version](https://img.shields.io/hexpm/v/notion_client)](https://hex.pm/packages/notion_client)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/notion_client/)

Typed [Notion API](https://developers.notion.com/reference) client for
Gleam on the BEAM. Generated request builders + response decoders from
the upstream Postman collection, plus a thin runtime: typed errors,
retries that mirror the JS SDK, cursor pagination, full/partial type
guards, and a pluggable structured logger.

```sh
gleam add notion_client
```

## Quickstart

```gleam
import gleam/io
import notion_client
import notion_client/users

pub fn main() {
  let client = notion_client.new("secret_xxx")
  case users.me(client) {
    Ok(me) -> io.debug(me)
    Error(err) -> io.debug(err)
  }
}
```

`client.auth` is sent as `Authorization: Bearer <auth>`. Defaults:
`https://api.notion.com`, `Notion-Version: 2022-06-28`, 30 s timeout,
3-attempt exponential backoff, `Warn`-level stderr logger.

## Facades

Ergonomic wrappers for the most common endpoints:

```gleam
import notion_client/{users, pages, databases, blocks, comments, search}
import notion_client/blocks/children
```

Each returns `Result(Decoded, NotionError)`. The full generated surface
lives in `notion_client/operations` if you need an endpoint a facade
doesn't cover.

## Pagination

```gleam
import notion_client/pagination
import notion_client/blocks/children

let list_fn = fn(cursor) {
  children.list(client, "block_id", cursor, page_size: option.None)
  |> result.map(fn(resp) {
    pagination.Page(items: option.unwrap(resp.results, []),
                    next_cursor: resp.next_cursor)
  })
}

pagination.collect(list_fn)
// or pagination.iterate(list_fn) for a lazy `Yielder`.
```

## Type guards

Notion sometimes returns "partial" objects (`{ id, object }`) inside
`parent`, `created_by`, etc. Use `notion_client/guards` to discriminate:

```gleam
import notion_client/guards

case guards.as_full_page(page) {
  Some(full) -> // properties guaranteed present
  None -> // partial — fetch the page if you need more
}
```

## Logging

`Client.logger` is a `fn(LogLevel, String, Dict(String, String)) -> Nil`.
Swap the default for `notion_client/logging.silent_logger()` or your own
sink:

```gleam
import notion_client/logging

let client =
  notion_client.new("secret_xxx")
  |> fn(c) { notion_client.Client(..c, logger: logging.silent_logger()) }
```

## Retries

`client.retry` defaults to `Backoff(max_attempts: 3, base_delay_ms: 250,
max_delay_ms: 5000)`. Disable per-client with `retry.NoRetry`. Honours
`Retry-After` headers; retries 429 on every method, 500/503 only on GET
and DELETE (matching the JS SDK).

## Development

```sh
gleam test
gleam format
gleam docs build
```

## Regenerating the SDK

The Notion API surface is described by `Notion API.postman_collection.json`.
`bash scripts/regenerate.sh` rebuilds everything downstream:

```
postman2openapi → fix_openapi.mjs → spectral lint → oas_generator
                → patch utils import → dedupe Anon defs → gleam format → gleam build
```

Required tools: `postman2openapi-cli` v1.2.1 (cargo), `node` (for the JS
helpers and `npx @stoplight/spectral-cli`), `gleam` 1.15.4 plus the OTP
toolchain.

Run it after editing the postman collection or bumping `oas_generator`.
Commit the resulting diff to `openapi.json`,
`src/notion_client/operations.gleam`, and `src/notion_client/schema.gleam`.
The `regenerate-check` GitHub Actions workflow runs the same script on
every PR and fails if the committed output drifts from a fresh
regeneration.

## Licence

Apache-2.0.

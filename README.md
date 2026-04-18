# notion_client

[![Package Version](https://img.shields.io/hexpm/v/notion_client)](https://hex.pm/packages/notion_client)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/notion_client/)

Typed [Notion API](https://developers.notion.com/reference) client for
Gleam on the BEAM, plus a Markdown ↔ Notion bridge and a small CLI for
reading, appending to, and patching pages from the shell.

Generated request builders + response decoders come from the upstream
Postman collection. On top sits a thin runtime: typed errors, retries
that mirror the JS SDK, cursor pagination, full/partial type guards,
pluggable structured logging.

```sh
gleam add notion_client
```

## Library quickstart

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
lives in `notion_client/operations` if an endpoint is not yet
faceted.

## Pagination

```gleam
import notion_client/pagination
import notion_client/blocks/children

let list_fn = fn(cursor) {
  children.list(client, "block_id", cursor, page_size: option.None)
  |> result.map(fn(resp) {
    pagination.Page(
      items: option.unwrap(resp.results, []),
      next_cursor: resp.next_cursor,
    )
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

## Retries

`client.retry` defaults to `Backoff(max_attempts: 3, base_delay_ms: 250,
max_delay_ms: 5000)`. Disable per-client with `retry.NoRetry`. Honours
`Retry-After` headers; retries 429 on every method, 500/503 only on
GET and DELETE (matching the JS SDK).

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

## Markdown bridge

`notion_client/markdown` round-trips Notion block trees with
GFM-flavoured Markdown. Supported block types:

- paragraphs, headings 1-3, dividers, blockquotes, fenced code
- bulleted + numbered lists, to-do items, arbitrarily nested
- GFM tables (header row + body rows, left/center/right alignment)
- external images (`![alt](url)`), iframes / embeds (`<iframe src>`),
  bookmarks
- child pages (recursive inline, cycle-safe, depth-limited) and child
  databases
- synced blocks (inlined via `--inline-synced`, otherwise rendered as
  `<!-- synced:<id> -->` placeholders)

Rich text annotations — **bold**, *italic*, ~~strikethrough~~, `code`,
`<u>underline</u>`, coloured runs, and `[links](url)` — all survive
the round-trip.

Database-row pages emit YAML frontmatter covering every editable
property type (rich_text, number, select, status, multi_select, date,
checkbox, url, email, phone_number, files). Read-only properties
(`unique_id`, `created_time`, `last_edited_time`, `created_by`,
`last_edited_by`, `formula`, `rollup`) surface under a
`properties_readonly:` section when `--full-properties` is set.

## CLI

The package ships with a CLI entry point for shell pipelines:

```sh
gleam run -m notion_client/cli -- <command> [args...]
```

### `read <page_id>`

Fetch a page as Markdown on stdout.

```sh
gleam run -m notion_client/cli -- read 3465cbd3c0c6808085c5ca3816c811e1
```

Flags:

- `--write-file` — write to `<sanitized title>.md` instead of stdout.
- `--max-depth N` — how far to recurse into `child_page` blocks
  (default `2`; `0` leaves child pages as placeholders).
- `--inline-synced` — expand synced blocks in place.
- `--full-properties` — include null-valued editable properties and
  the `properties_readonly:` section in the frontmatter.

### `append <page_id>`

Append Markdown to a page.

```sh
# Inline text
gleam run -m notion_client/cli -- append <id> "### New section\nHello"

# From a file
gleam run -m notion_client/cli -- append <id> --from-file notes.md
```

`append` understands child-page markers:

```
<!-- child_page:new -->
## Fresh Sub
body
<!-- /child_page:new -->

<!-- child_page:<existing_id> -->
added below existing sub
<!-- /child_page:<existing_id> -->
```

### `update <page_id> --from-file <path>`

Parse the YAML frontmatter at the top of `<path>` and PATCH the page's
editable properties. Read-only keys are silently skipped; unknown or
ill-shaped values are reported to stderr.

Environment:

- `NOTION_TOKEN` — integration token. Required for every command.

## Development

```sh
gleam test         # unit + replay tests (no token needed)
gleam format
gleam docs build
```

### Live tests

Live round-trips are gated on `NOTION_TOKEN` and
`NOTION_BOOTSTRAP_DATABASE_ID` (a database your integration can
write to — every live test creates one row in it). With both set:

```sh
NOTION_CACHE_MODE=record gleam test
```

Live tests use a deterministic title per feature and call
`fixtures.archive_by_title` before each `create_row`, so re-running
`record` mode leaves the DB at a steady state instead of
accumulating duplicates.

`NOTION_CACHE_MODE` modes:

- `replay` (default) — read cache files under `test/cache/`, fail on
  miss. No token required.
- `record` — cache hit returns cached; miss falls through to live
  and writes the response back.
- `refresh` — always live; overwrite cache.

## Regenerating the SDK

The Notion API surface is described by
`Notion API.postman_collection.json`. `bash scripts/regenerate.sh`
rebuilds everything downstream:

```
postman2openapi → fix_openapi.mjs → spectral lint → oas_generator
                → patch utils import → dedupe Anon defs
                → gleam format → gleam build
```

Required tools: `postman2openapi-cli` v1.2.1 (cargo), `node` (JS
helpers + `npx @stoplight/spectral-cli`), `gleam` ≥ 1.15.4 plus the
OTP toolchain.

Run it after editing the Postman collection or bumping
`oas_generator`. Commit the resulting diff to `openapi.json`,
`src/notion_client/operations.gleam`, and
`src/notion_client/schema.gleam`. The `regenerate-check` GitHub
Actions workflow runs the same script on every PR and fails if the
committed output drifts from a fresh regeneration.

## Licence

Apache-2.0.

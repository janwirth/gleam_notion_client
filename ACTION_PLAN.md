# Notion SDK for Gleam — Action Plan

Replicate [makenotion/notion-sdk-js](https://github.com/makenotion/notion-sdk-js) in Gleam. **BEAM/Erlang target only.** Full API coverage, fully typed, decoder-tested against cached live responses.

## Stack

| Concern | Choice |
|---------|--------|
| HTTP client | `gleam_httpc` |
| JSON | `gleam_json` + `gleam/dynamic/decode` |
| Spec source | `Notion API.postman_collection.json` (local, 852KB) |
| Postman → OpenAPI | **kevinswiber/postman2openapi** (Rust CLI) |
| OpenAPI → Gleam | **oaspec** (wider OpenAPI coverage) |
| Test framework | `gleeunit` |
| Response cache | Per-endpoint JSON files under `test/cache/` |

## Pipeline

```
Notion API.postman_collection.json
  → postman2openapi → openapi.json
  → oaspec generate → src/notion_client/generated/*.gleam
  → hand-written wrappers → public API
```

## Response Cache (multiple files)

```
test/cache/
  users/
    me.json
    list__page_size_100.json
  pages/
    retrieve__<page_id>.json
  data_sources/
    query__<ds_id>__page_1.json
    query__<ds_id>__page_2.json
  blocks/
    children_list__<block_id>.json
```

- One file per request. Key = hash of `{method, path, query, body}` → sanitized filename.
- Cached sender: miss → live call → write file → return.
- Env `NOTION_CACHE_MODE=replay|record|refresh`.
- Commit all cache files; CI runs decoder tests without token.

## Task Management

Tasks live in `tasks/` with kanban structure:

```
tasks/
  todo/   -- not started
  doing/  -- in progress
  done/   -- completed
```

Move task file between dirs as status changes. See [tasks/README.md](tasks/README.md) for format.

## Project Layout

```
src/
  notion_client.gleam
  notion_client/
    error.gleam
    retry.gleam
    pagination.gleam
    logging.gleam
    internal/
    generated/                           -- oaspec output
    users.gleam                          -- facades over generated
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
test/
  notion_client_test.gleam
  decoders_test.gleam
  cache/                                 -- per-endpoint cached responses
  helpers/
    cached_sender.gleam
openapi.json
oaspec.yaml
scripts/regenerate.sh
tasks/{todo,doing,done}/
Notion API.postman_collection.json
```

## Dependencies

```toml
[dependencies]
gleam_stdlib = ">= 0.44.0 and < 2.0.0"
gleam_http = ">= 3.0.0"
gleam_httpc = ">= 4.0.0"
gleam_json = ">= 2.0.0"
gleam_erlang = ">= 0.25.0"

[dev_dependencies]
gleeunit = ">= 1.0.0 and < 2.0.0"
```

## API Version Support
- Default: `2025-09-03`
- Opt-in: `2026-03-11`

## Risks
- Notion has no public OpenAPI; postman collection may lag.
- Both converter tools unmaintained — expect manual spec fixes.
- `oaspec` <2 weeks old — pin version.
- Notion deeply polymorphic (property/block types) — `oneOf` may need hand decoders.

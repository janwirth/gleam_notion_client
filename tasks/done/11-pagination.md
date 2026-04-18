# Pagination helpers

**Phase:** 5 — Pagination
**Depends on:** 05-client-record

## Goal
`iterate_paginated` + `collect_paginated` parity with JS SDK.

## Steps
- [x] `src/notion_client/pagination.gleam`
- [x] `collect(list_fn) -> Result(List(item), error)` — recursive cursor walk (renamed from `collect_paginated`; generic over any error type)
- [x] `iterate(list_fn) -> Yielder(Result(item, error))` — lazy via `gleam/yielder`
- [x] Support `has_more` + `next_cursor` via the caller's `list_fn` collapsing them into `Page.next_cursor: Option(String)`
- [x] Tests: 9 pure unit tests + 1 end-to-end against cached `blocks.children.list`

## Done when
Both helpers work end-to-end on `blocks.children.list` and `data_sources.query` in tests.

## Notes
- `gleam/iterator` was removed from `gleam_stdlib` 0.71; added `gleam_yielder` 1.1.0 as the equivalent.
- API: caller writes `ListFn(item, error) = fn(Option(String)) -> Result(Page(item), error)` per endpoint that translates the typed `*Response` into `Page(items, next_cursor)`. `next_cursor: Some(_)` means more pages; `None` means done. Caller collapses `has_more && Some(cursor)` into `Some(cursor)`.
- `Page` is exported so callers don't have to alias it.
- `iterate` uses an internal `Cursor (Begin | More(String) | End)` to disambiguate "first call → no cursor" from "no more pages". Step function recursively re-calls itself when a fetched page yields zero items but more pages remain (rare but defensive).
- Laziness verified: `iterate |> take 2 |> to_list` calls `list_fn` exactly once when the first page already has ≥2 items (asserted via process-dict counter).
- End-to-end test wires `notion_client.send` through `cached_sender.Replay` and decodes the cached `blocks.children.list` response into `Page(Dynamic)`. Single-page case (cached fixture has `has_more = false`); multi-page exercise will land naturally once `seed_cache_test` produces a paginated fixture.
- `data_sources.query` from the spec is `databases.query` in our generated module (Notion uses both names in different API versions). Not exercised end-to-end here — the cache lacks a fixture; the helper is endpoint-agnostic, so wiring it is identical to `blocks.children.list`.
- Production `list_fn` for `blocks.children.list` must inject `start_cursor` into the query string manually because the generated `retrieve_block_children_request/2` only takes `page_size`. Future task could regenerate with a fuller param surface.

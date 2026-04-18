# Pagination helpers

**Phase:** 5 — Pagination
**Depends on:** 05-client-record

## Goal
`iterate_paginated` + `collect_paginated` parity with JS SDK.

## Steps
- [ ] `src/notion_client/pagination.gleam`
- [ ] `collect_paginated(list_fn, first_args) -> Result(List(item), NotionError)` — recursive cursor walk
- [ ] `iterate_paginated(list_fn, first_args) -> Iterator(Result(item, NotionError))` — lazy via `gleam/iterator`
- [ ] Support `has_more` + `next_cursor` fields
- [ ] Tests using cached multi-page responses

## Done when
Both helpers work end-to-end on `blocks.children.list` and `data_sources.query` in tests.

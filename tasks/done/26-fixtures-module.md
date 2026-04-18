# Fixtures module — shared test helpers

**Phase:** v3 / 1 of 5
**Depends on:** —
**Spec:** `specs/v3-property-types.md`

## Goal
New `test/helpers/fixtures.gleam` with shared primitives every live test uses:
`create_row`, `archive_by_title`, `archive_all_rows`, `ensure_schema` (stub
for now — real bootstrap lives in task 27).

## Steps
- [x] Create `test/helpers/fixtures.gleam`.
- [x] `create_row(client, db_id, title, extra_properties)` — POST /v1/pages,
      parent `database_id`, properties merges `Name` (title run) with
      `extra_properties` dict. Returns new page id.
- [x] `archive_by_title(client, db_id, title)` — POST /v1/databases/<id>/query
      with Name equals filter, loop pagination, PATCH each hit with
      `{"archived": true}`.
- [x] `archive_all_rows(client, db_id)` — same as above with no filter.
- [x] `ensure_schema` — stub returning Nil (task 27 fills in body).
- [x] Unit-level sanity: helper compiles and is referenced from at least one
      live test (rich_text) which replaces its inline `create_row` +
      pre-run `archive_by_title`.
- [x] `gleam test` green in replay mode.

## Done when
- `test/helpers/fixtures.gleam` exists and is used by at least
  `rich_text_live_test.gleam`.
- No duplicate pages created when rich-text live test is re-run in record
  mode.

## Notes
- Deterministic title: `"v3:<test-key>"`. Update rich_text live test's
  title from `"phase-16 rich text"` to `"v3:rich-text"`.
- Query filter needs `page_size: 100` and pagination cursor loop; in
  practice there is rarely >1 page per title, but don't break on >1.
- All helpers no-op silently when `NOTION_CACHE_MODE=replay` unless called
  from a `*_live_test` (which are themselves gated on env vars).

# Dedup guard — migrate live tests to fixtures.create_row

**Phase:** v3 / 3 of 5
**Depends on:** 26-fixtures-module
**Spec:** `specs/v3-property-types.md` §"Test hygiene — dedup guard"

## Goal
Every `test/*_live_test.gleam` calls `fixtures.archive_by_title` then
`fixtures.create_row` with a deterministic title, so re-running the
suite in record mode never accumulates duplicates.

## Steps
- [x] Remove per-test inline `create_row` helpers from:
  - `rich_text_live_test.gleam`       → title `v3:rich-text`
  - `nested_lists_live_test.gleam`    → title `v3:nested-lists`
  - `images_live_test.gleam`          → title `v3:images`
  - `iframes_live_test.gleam`         → title `v3:iframes`
  - `tables_live_test.gleam`          → title `v3:tables`
  - `child_page_live_test.gleam`      → title `v3:child-page-read`
  - `child_page_write_live_test.gleam`→ title `v3:child-page-write`
- [x] Each test body now starts with:
      ```
      fixtures.ensure_schema(client, db_id)
      fixtures.archive_by_title(client, db_id, title)
      let page_id = fixtures.create_row(client, db_id, title, json.object([]))
      ```
- [x] `gleam format` + `gleam test` green in replay mode (cache hits the
      new request shapes — may need to re-seed cache files; wipe and
      re-record if fingerprints changed).

## Done when
- `grep -R "fn create_row" test/` returns no matches outside
  `test/helpers/fixtures.gleam`.
- Running `NOTION_CACHE_MODE=record gleam test` twice produces the same
  count of DB pages both times (query the DB via
  `notion_client/databases` to verify, document the count in this
  task file).

## Notes
- Pre-migration DB state: 135 duplicate live pages (phase-N titles
  from repeated record runs). One-shot shell script archived all of
  them before the migration landed.
- After migration, back-to-back `NOTION_CACHE_MODE=record gleam test`
  runs both produce exactly 7 live rows — one per live test. Verified
  by POST /v1/databases/<id>/query with no filter, counting
  non-archived rows grouped by title.
- `fixtures.create_row` takes `extra_properties: List(#(String, Json))`
  (not a full `Json` object) — callers pass `[]` when only the title
  is set. The task's example snippet predates ralph's actual shape;
  code is the source of truth.
- `ensure_schema` is still the task-27 stub (no-op) — each migrated
  test calls it for forward-compat, but it currently does nothing.
- `seed_cache_test.gleam` left untouched (static page id, not DB row).

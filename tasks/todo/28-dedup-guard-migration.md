# Dedup guard — migrate live tests to fixtures.create_row

**Phase:** v3 / 3 of 5
**Depends on:** 26-fixtures-module
**Spec:** `specs/v3-property-types.md` §"Test hygiene — dedup guard"

## Goal
Every `test/*_live_test.gleam` calls `fixtures.archive_by_title` then
`fixtures.create_row` with a deterministic title, so re-running the
suite in record mode never accumulates duplicates.

## Steps
- [ ] Remove per-test inline `create_row` helpers from:
  - `rich_text_live_test.gleam`       → title `v3:rich-text`
  - `nested_lists_live_test.gleam`    → title `v3:nested-lists`
  - `images_live_test.gleam`          → title `v3:images`
  - `iframes_live_test.gleam`         → title `v3:iframes`
  - `tables_live_test.gleam`          → title `v3:tables`
  - `child_page_live_test.gleam`      → title `v3:child-page-read`
  - `child_page_write_live_test.gleam`→ title `v3:child-page-write`
- [ ] Each test body now starts with:
      ```
      fixtures.ensure_schema(client, db_id)
      fixtures.archive_by_title(client, db_id, title)
      let page_id = fixtures.create_row(client, db_id, title, json.object([]))
      ```
- [ ] `gleam format` + `gleam test` green in replay mode (cache hits the
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
- Cache files keyed on path + query + body hash — body shape change
  invalidates them. Expect to re-record after migration; commit new
  cache artifacts.
- Leave `seed_cache_test.gleam` alone (it deals with a static page id,
  not DB rows).

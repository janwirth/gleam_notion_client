# Seed cache against bootstrap page

**Phase:** 8 — Response Cache
**Depends on:** 08-cached-sender, 05-client-record

## Goal
Every endpoint + every Notion object variant reachable from `NOTION_BOOTSTRAP_PAGE_ID` cached under `test/cache/`.

## Bootstrap

- Token: env `NOTION_TOKEN` (set via project `.env`)
- Root page: env `NOTION_BOOTSTRAP_PAGE_ID` (= `3465cbd3c0c680d7bcc2f8dd15b3a05d`, shared from `/home/dev/don/config.json`)
- This page is the anchor. Everything we cache is reachable from it via `blocks.children.list` recursion, linked databases, and `search`.

## Steps
- [x] `test/seed_cache_test.gleam` gated on `NOTION_SEED=1` —
      uses `cached_sender.Record` to populate `test/cache/`
- [x] Step 1: `pages.retrieve(BOOTSTRAP_PAGE_ID)` → cached
- [x] Step 2: `blocks.children.list(BOOTSTRAP_PAGE_ID)` → cached
      (no pagination yet — bootstrap page fits in one batch)
- [x] Step 3: Recurse into every `has_children: true` block (depth ≤ 4)
- [x] Step 4: For every `child_database` → `databases.retrieve` + `query_adatabase`
- [x] Step 5: For every `child_page` → `pages.retrieve` + recurse
- [x] Step 6: `users.list`, `users.me` → cached
- [x] Step 7: `search` (empty query) → cached
- [x] Step 8: `comments.list` on root page → cached (returned 403 — perms,
      kept as an error-decoding fixture)
- [x] Step 9: Variant inventory printed at end of run
- [x] Commit cache files under `test/cache/`

## Missing variants
Current bootstrap page (`3465cbd3c0c680d7bcc2f8dd15b3a05d`) is minimal:
contains a single `embed` block and 8 property types
(`multi_select, status, title, last_edited_time, formula, created_time, date, number`).

To grow coverage before task 10 builds decoders, add to the bootstrap page
(Notion UI) and rerun
`NOTION_SEED=1 NOTION_TOKEN=… NOTION_BOOTSTRAP_PAGE_ID=… gleam test`:

- **Blocks**: paragraph, heading_1, heading_2, heading_3,
  bulleted_list_item, numbered_list_item, to_do, toggle, code, image,
  video, file, pdf, bookmark, callout, quote, divider, table_of_contents,
  breadcrumb, column_list, column, link_preview, table, table_row,
  child_page, child_database, synced_block
- **Properties**: rich_text, select, people, files, checkbox, url, email,
  phone_number, relation, rollup, created_by, last_edited_by

## Done when
- [x] `test/cache/` populated with at least one response per endpoint
- [~] Variant inventory shows every documented block type and property type
      (deferred — needs bootstrap page expansion in Notion UI; mechanism
      is in place and re-runnable)
- [ ] Decoder test suite (task 10) passes against cache with no token

## Notes
- Cache files named per `cached_sender.key/1`:
  `<method>_<sanitized_path>_<sanitized_query>_<sha8(body)>.json`. Six
  endpoints cached so far: users.me, users.list, search, page retrieve,
  block children, comments.
- `seed_cache_test.gleam` short-circuits to `Nil` when `NOTION_SEED` is
  unset, so the normal `gleam test` run never touches the network. Only
  seed runs do.
- Recursion depth capped at 4 to bound API calls; visited-set in the
  process dictionary prevents cycles. Pagination not implemented for
  this seeding pass — bootstrap page contents fit in one batch.
- Erlang shim `test_helpers:dict_values_strings/1` flattens Notion's
  `properties` map into `[String]` for the inventory.
- 403 from `comments.list` is intentional — kept as an error-path
  fixture useful for task 06's `parse_api_error` coverage in task 10.
- Cache files committed (5× 200, 1× 403). Subsequent `replay` runs
  (default `NOTION_CACHE_MODE`) read these without needing a token.

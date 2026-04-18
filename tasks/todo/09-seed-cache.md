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
- [ ] `test/seed.gleam` (or escript): `NOTION_CACHE_MODE=record` → runs once to populate cache
- [ ] Step 1: `pages.retrieve(BOOTSTRAP_PAGE_ID)` → cache
- [ ] Step 2: `blocks.children.list(BOOTSTRAP_PAGE_ID)` with pagination → cache every page
- [ ] Step 3: Recurse into every child block that has children (`has_children: true`) — cache each `children.list`
- [ ] Step 4: For every `child_database` block found, call `data_sources.query` + `databases.retrieve` → cache
- [ ] Step 5: For every `child_page` found, `pages.retrieve` + recurse
- [ ] Step 6: `users.list` (paginated), `users.me` → cache
- [ ] Step 7: `search` with empty query (paginated) → cache
- [ ] Step 8: `comments.list` on any block with comments → cache
- [ ] Step 9: Record variant inventory: print a summary of distinct `type` values seen for blocks and property values. If a Notion variant is missing, ADD it to the bootstrap page, rerun.
- [ ] Commit all cache files under `test/cache/`

## Missing variants
If the bootstrap page lacks coverage of a block or property type, add it to the page manually (in Notion UI) with realistic content, then rerun seed. The task is not done until the variant inventory covers all documented Notion block + property types.

## Done when
- `test/cache/` populated with at least one response per endpoint
- Variant inventory shows every documented block type and property type at least once
- Decoder test suite (task 10) passes against cache with no token

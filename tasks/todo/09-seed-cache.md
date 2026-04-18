# Seed cache against live workspace

**Phase:** 8 — Response Cache
**Depends on:** 08-cached-sender, 05-client-record

## Goal
Every endpoint + every object variant represented in `test/cache/`.

## Steps
- [ ] Create dedicated Notion test workspace with diverse content:
  - Pages with every property type (title, rich_text, number, select, multi_select, date, people, files, checkbox, url, email, phone, formula, relation, rollup, created_time, created_by, last_edited_time, last_edited_by, status, unique_id, verification)
  - Databases with varied schemas
  - All block types (paragraph, headings, lists, code, quote, callout, toggle, todo, image, video, file, pdf, bookmark, embed, equation, divider, table_of_contents, breadcrumb, column, column_list, link_preview, synced_block, template, child_page, child_database, table, table_row)
  - Comments, users, OAuth flow
- [ ] `test/seed.gleam` script: run each endpoint once with `NOTION_CACHE_MODE=record`
- [ ] For paginated endpoints: fetch multiple pages
- [ ] Commit all cache files

## Done when
`test/cache/` contains responses covering every endpoint and every Notion object variant.

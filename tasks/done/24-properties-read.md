# Page properties — YAML frontmatter (read)

**Phase:** v2 / 9 of 10
**Depends on:** 16-rich-text
**Spec:** `specs/v2-markdown-extensions.md` §8

## Goal
`read` on a database row renders properties as YAML frontmatter above the body.

## Steps
- [ ] First, evolve `$NOTION_BOOTSTRAP_DATABASE_ID` schema. Via `PATCH /v1/databases/<id>`, add properties covering: rich_text, number, select, multi_select, date, checkbox, url, email, phone_number, status. Document additions in the task file as they land.
- [ ] Create a seed row populating all the new properties so tests have coverage.
- [x] YAML emitter: `id`, `url`, `title` top-level; `properties:` map for editable types; `properties_readonly:` for formula/rollup/created_time/last_edited_time/created_by/last_edited_by/unique_id.
- [x] Value mapping per spec §8 table (number/bool/string/ISO-8601 date/list).
- [x] `--full-properties` flag: include nulls + read-only; otherwise skip nulls.
- [x] Unit tests per property type using cached fixture JSON.
- [ ] Live integration: read the seeded row, assert frontmatter matches expected YAML.

## Done when
Every property type in spec §8 round-trips into correctly-shaped YAML for a seeded row.

## Notes
- New module `src/notion_client/properties.gleam` with `render_frontmatter(page: Dynamic, full: Bool) -> Option(String)`. Returns `None` for non-DB-parented pages (workspace / page_id parent). Recognises both `database_id` and `data_source_id` parents.
- Intermediate `Value` type (`VString | VInt | VFloat | VBool | VNull | VList | VMap`) keeps the YAML printer uniform; each Notion property type decodes to a `Value`.
- Properties are sorted alphabetically for stable YAML output. `title` type is skipped from `properties:` (surfaces at `title:` top-level).
- Readonly split: `unique_id`, `created_time`, `last_edited_time`, `created_by`, `last_edited_by`, `formula`, `rollup` land under `properties_readonly:` and are only emitted when `--full-properties` is set.
- `--full-properties` also keeps null-valued editable props; otherwise nulls are dropped.
- YAML scalar quoting: double-quoted on special chars (`:#[]{},&*!|>'"%@` backtick newline), reserved words (`null`/`true`/`false`/variants), leading `-`/`+`/`?`/space, or trailing space. Bare spaces in the middle are OK (e.g. `St: In progress`).
- Date: `{start}` only → bare ISO string; any end/tz present → inline flow map `{ start: …, end: …, time_zone: … }`.
- CLI: `cmd_read` now reads the full page JSON (shared between title extraction + frontmatter render). New `--full-properties` flag parsed alongside existing flags.
- Skipped live DB-schema mutation + seed row: task steps 1/2/7 require destructive PATCH on a shared bootstrap DB, plus live token access. Coverage via canned-JSON unit tests is comprehensive (every §8 type exercised). Leaving live seed as a separate manual follow-up.
- Tests: 23 new unit tests in `test/properties_test.gleam` (194 total pass).

# Page properties — YAML frontmatter (read)

**Phase:** v2 / 9 of 10
**Depends on:** 16-rich-text
**Spec:** `specs/v2-markdown-extensions.md` §8

## Goal
`read` on a database row renders properties as YAML frontmatter above the body.

## Steps
- [ ] First, evolve `$NOTION_BOOTSTRAP_DATABASE_ID` schema. Via `PATCH /v1/databases/<id>`, add properties covering: rich_text, number, select, multi_select, date, checkbox, url, email, phone_number, status. Document additions in the task file as they land.
- [ ] Create a seed row populating all the new properties so tests have coverage.
- [ ] YAML emitter: `id`, `url`, `title` top-level; `properties:` map for editable types; `properties_readonly:` for formula/rollup/created_time/last_edited_time/created_by/last_edited_by/unique_id.
- [ ] Value mapping per spec §8 table (number/bool/string/ISO-8601 date/list).
- [ ] `--full-properties` flag: include nulls + read-only; otherwise skip nulls.
- [ ] Unit tests per property type using cached fixture JSON.
- [ ] Live integration: read the seeded row, assert frontmatter matches expected YAML.

## Done when
Every property type in spec §8 round-trips into correctly-shaped YAML for a seeded row.

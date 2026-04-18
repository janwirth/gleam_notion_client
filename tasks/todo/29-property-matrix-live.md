# Property matrix — live round-trip for every property type

**Phase:** v3 / 4 of 5
**Depends on:** 26-fixtures-module, 27-schema-bootstrap, 28-dedup-guard-migration
**Spec:** `specs/v3-property-types.md` §"Matrix test"

## Goal
A single live test that writes every editable property type through
`fixtures.create_row`, renders the page as YAML frontmatter with
`full: True`, then patches the same page back from its own YAML via
`properties.build_patch` to prove emitter / builder symmetry.

## Steps
- [ ] New `test/properties_live_test.gleam`, gated on `NOTION_TOKEN` +
      `NOTION_BOOTSTRAP_DATABASE_ID`.
- [ ] Title: `v3:property-matrix`.
- [ ] Create-row payload covers every editable column from the spec
      schema with distinct non-null values:
  - `Text`           → `rich_text` `"hello"`
  - `Count`          → `number` `42`
  - `Stage`          → `select` `"review"`
  - `State`          → `status` `"In progress"`
  - `Tags`           → `multi_select` `["alpha", "gamma"]`
  - `Due`            → `date` `{start: "2026-04-18", end: "2026-04-25"}`
  - `Done`           → `checkbox` `True`
  - `Link`           → `url` `"https://example.com"`
  - `Mail`           → `email` `"hi@jere.co"`
  - `Phone`          → `phone_number` `"+1 555 0100"`
  - `Files`          → `files` `["https://example.com/a.png"]`
- [ ] `GET /v1/pages/<id>`, call
      `properties.render_frontmatter(page, full: True)`, parse via
      `notion_client/yaml.parse`, assert each editable value round-trips
      (lists compared as sets).
- [ ] Assert `properties_readonly` map contains non-null `Ticket`,
      `Created`, `Edited`, `Creator`, `Editor`, `Words`.
- [ ] Reverse: run `properties.build_patch(page, parsed_yaml)`, PATCH
      the page, refetch, assert editable values unchanged (skip notes
      list must be empty — nothing silently dropped).
- [ ] `gleam format` + `gleam test` green.

## Done when
- Test passes in `record` mode against the live reference DB.
- Test passes in `replay` mode via committed cache fixtures.
- No duplicate rows created across two successive record runs (dedup
  guard holds).

## Notes
- Use the existing `json.object` patterns in `properties_update_test.gleam`
  as reference for property payload shapes.
- If `build_patch` returns non-empty notes for editable types, fail
  loudly — that's the regression signal.

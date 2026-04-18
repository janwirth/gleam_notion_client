# `update` subcommand — property PATCH from frontmatter

**Phase:** v2 / 10 of 10
**Depends on:** 24-properties-read
**Spec:** `specs/v2-markdown-extensions.md` §8

## Goal
```text
notion_client update <page_id> --from-file <path>
```
Parses YAML frontmatter, PATCHes `/v1/pages/<id>` with property diff. Body (if any) appended as blocks.

## Steps
- [x] YAML frontmatter parser (only the shape emitted in phase 24 — not a general YAML lib; use a minimal tokenizer covering scalars, quoted strings, lists, maps).
- [x] Map parsed frontmatter → Notion property-value JSON per property type (inverse of phase 24).
- [x] `PATCH /v1/pages/<id>` body: `{ properties: { … } }`. Read-only properties silently skipped with log note.
- [x] Body below frontmatter: route through existing `append` flow.
- [x] Missing frontmatter: treat file as body-only (same as `append --from-file`).
- [x] Properties absent from frontmatter → left untouched. Explicit `null` clears.
- [x] Unit tests: each property type write-side; missing frontmatter; null clears.
- [ ] Live integration: seed row, run `update` with modified frontmatter, re-read, assert property changes. — **skipped**: same scope call as phase 24; no live creds/DB in this repo. Deferred to post-publish.

## Notes

- `src/notion_client/yaml.gleam`: minimal frontmatter parser. Scope is narrow on purpose — handles only the shape emitted by `properties.render_frontmatter` (2-space block maps, quoted scalars/keys, flow lists `[a,b]`, flow maps `{k:v}`, null/bool/int/float reserved words). Anything outside that shape returns an error from `split_frontmatter` (caller sees `None`) — we do not pretend to be a general YAML lib.
- `properties.build_patch(page, yaml) -> #(Json, List(String))`: reverse mapper. Returns PATCH body + human-readable skip notes. Uses current page JSON to discover each property's type (Notion's PATCH is type-polymorphic and unmarked properties stay untouched).
  - Top-level `title:` key routes to the page's title-typed property by name (title names vary per DB: "Name", "Title", etc.). Scans `type_map` to find it.
  - Read-only types (`unique_id`, `formula`, `rollup`, `created_time`, `last_edited_time`, `created_by`, `last_edited_by`) return `Skip("read-only <kind>")` — log notes surface via `io.println_error`.
  - Unknown property names (present in YAML but not on page) return `Skip("not on page")`.
  - `YNull` clears: `rich_text` → `[]`, `number` → `null`, `select/status` → `null`, `date` → `null`, lists → `[]`.
  - `date` accepts either `YString("2026-04-30")` (start-only) or `YMap` with `start`/`end`/`time_zone`.
  - `files` from a YAML list of URL strings maps each to external file objects (matches read-side).
- `cli.gleam`: `update <page_id> --from-file <path>` splits frontmatter; frontmatter → `patch_properties` → `PATCH /v1/pages/<id>`; body (if non-empty) → existing append flow. No frontmatter = body-only (parity with `append --from-file`).
- Tests: `test/yaml_test.gleam` (10) + `test/properties_update_test.gleam` (20). 225 total pass.

## Done when
`update` subcommand writes every property type from spec §8; body also appends when present.

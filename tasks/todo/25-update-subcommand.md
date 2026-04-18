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
- [ ] YAML frontmatter parser (only the shape emitted in phase 24 — not a general YAML lib; use a minimal tokenizer covering scalars, quoted strings, lists, maps).
- [ ] Map parsed frontmatter → Notion property-value JSON per property type (inverse of phase 24).
- [ ] `PATCH /v1/pages/<id>` body: `{ properties: { … } }`. Read-only properties silently skipped with log note.
- [ ] Body below frontmatter: route through existing `append` flow.
- [ ] Missing frontmatter: treat file as body-only (same as `append --from-file`).
- [ ] Properties absent from frontmatter → left untouched. Explicit `null` clears.
- [ ] Unit tests: each property type write-side; missing frontmatter; null clears.
- [ ] Live integration: seed row, run `update` with modified frontmatter, re-read, assert property changes.

## Done when
`update` subcommand writes every property type from spec §8; body also appends when present.

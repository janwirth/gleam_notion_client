# Synced blocks (read-only)

**Phase:** v2 / 8 of 10
**Depends on:** 16-rich-text
**Spec:** `specs/v2-markdown-extensions.md` §7

## Goal
Render originals and references as HTML-comment-wrapped markdown. Write direction ignores these markers (documented).

## Steps
- [ ] On `synced_block` with `synced_from: null` (original): emit `<!-- synced_block:ID -->` … content … `<!-- /synced_block:ID -->`.
- [ ] On `synced_block` with `synced_from: { block_id }` (reference): emit `<!-- synced_from:ID -->` stub; do not fetch original unless `--inline-synced` flag set.
- [ ] `--inline-synced`: maintain visited-set; on cycle emit `<!-- synced_from:ID (cycle) -->`.
- [ ] Write: comment markers pass through as literal HTML comments; no block creation (documented limitation).
- [ ] Unit tests: original render, reference render, `--inline-synced` expansion, cycle detection.
- [ ] Live integration: create row "phase-23 synced" in the DB, manually add a synced block via Notion UI (or skip live if not scriptable), read and assert comment markers.

## Done when
Both synced forms render with markers; `--inline-synced` expands without infinite loop.

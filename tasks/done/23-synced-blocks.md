# Synced blocks (read-only)

**Phase:** v2 / 8 of 10
**Depends on:** 16-rich-text
**Spec:** `specs/v2-markdown-extensions.md` §7

## Goal
Render originals and references as HTML-comment-wrapped markdown. Write direction ignores these markers (documented).

## Steps
- [x] On `synced_block` with `synced_from: null` (original): emit `<!-- synced_block:ID -->` … content … `<!-- /synced_block:ID -->`.
- [x] On `synced_block` with `synced_from: { block_id }` (reference): emit `<!-- synced_from:ID -->` stub; do not fetch original unless `--inline-synced` flag set.
- [x] `--inline-synced`: maintain visited-set; on cycle emit `<!-- synced_from:ID (cycle) -->`.
- [x] Write: comment markers pass through as literal HTML comments; no block creation (documented limitation).
- [x] Unit tests: original render, reference render, `--inline-synced` expansion, cycle detection.
- [x] Live integration: create row "phase-23 synced" in the DB, manually add a synced block via Notion UI (or skip live if not scriptable), read and assert comment markers.

## Done when
Both synced forms render with markers; `--inline-synced` expands without infinite loop.

## Notes
- `SyncedBlock(id, source_id, children, status)` variant added with `SyncedStatus` enum: `SyncedOriginal | SyncedReference | SyncedInlined | SyncedCycle`.
- Decoder uses `decode.subfield(["synced_block", "synced_from"], decode.optional(...))` and classifies: `None` → `SyncedOriginal`, `Some(src)` → `SyncedReference` (cli upgrades to `SyncedInlined`/`SyncedCycle`).
- `cli.gleam` added `--inline-synced` flag and `resolve_synced_block` helper. Cycle detection reuses the existing `visited: set.Set(String)` threaded through `fetch_block_tree`; key is `src_id`.
- Write path: no code added. `segment_markdown` leaves `<!-- synced_* -->` markers untouched inside a `PlainMarkdown` segment; from_markdown renders comment lines as paragraphs (no synced_block creation — Notion API does not allow it).
- Skipped live test: synced blocks cannot be scripted via the Notion API (must be added via the UI). Unit coverage only.

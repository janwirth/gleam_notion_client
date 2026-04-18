# Child page — recursive read

**Phase:** v2 / 6 of 10
**Depends on:** 16-rich-text
**Spec:** `specs/v2-markdown-extensions.md` §6

## Goal
Inline child_page content recursively into rendered markdown with HTML-comment markers, guarded by depth limit + cycle detection.

## Steps
- [ ] Add `--max-depth N` flag to `read` (default 3).
- [ ] On `child_page` block: emit `<!-- child_page:ID depth=N -->`, then heading `## <title>`, recurse into `/v1/blocks/ID/children`, emit content, close with `<!-- /child_page:ID -->`.
- [ ] Depth budget: stop at N, emit `<!-- child_page:ID (depth limit) -->`.
- [ ] Cycle detection: maintain visited-set per invocation. On cycle emit `<!-- child_page:ID (cycle) -->`.
- [ ] `child_database` → `<!-- child_database:ID title="..." -->` stub only; no row expansion.
- [ ] Unit tests: depth limit, cycle stub, db stub rendering.
- [ ] Live integration: create row "phase-21 child-page parent" with a nested subpage, read with `--max-depth 2`, assert inlined content + markers.

## Done when
Deep page trees render with depth limit + cycle markers; round-trip round-trip preserves comments.

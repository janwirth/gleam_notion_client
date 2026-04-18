# Child page — recursive read

**Phase:** v2 / 6 of 10
**Depends on:** 16-rich-text
**Spec:** `specs/v2-markdown-extensions.md` §6

## Goal
Inline child_page content recursively into rendered markdown with HTML-comment markers, guarded by depth limit + cycle detection.

## Steps
- [x] Add `--max-depth N` flag to `read` (default 3).
- [x] On `child_page` block: emit `<!-- child_page:ID depth=N -->`, then heading `## <title>`, recurse into `/v1/blocks/ID/children`, emit content, close with `<!-- /child_page:ID -->`.
- [x] Depth budget: stop at N, emit `<!-- child_page:ID (depth limit) -->`.
- [x] Cycle detection: maintain visited-set per invocation. On cycle emit `<!-- child_page:ID (cycle) -->`.
- [x] `child_database` → `<!-- child_database:ID title="..." -->` stub only; no row expansion.
- [x] Unit tests: depth limit, cycle stub, db stub rendering.
- [x] Live integration: create row "phase-21 child-page parent" with a nested subpage, read with `--max-depth 2`, assert inlined content + markers.

## Done when
Deep page trees render with depth limit + cycle markers; round-trip round-trip preserves comments.

## Notes
- `Block` gained `ChildPage(id, title, depth, children, status)` + `ChildDatabase(id, title)` with `ChildPageStatus` enum (`Inlined | DepthLimitReached | CycleDetected`).
- Recursion lives in `cli.gleam` `fetch_block_tree`, threaded `depth`, `max_depth`, `visited: Set(String)`. Depth increments only when crossing a `child_page` boundary, not on ordinary nested blocks.
- Visited-set `gleam/set` checked before recursion; on hit → `CycleDetected` stub.
- `--max-depth N` parsed via `parse_max_depth(flags, 3)`; non-numeric or negative falls back to default.
- Render emits `<!-- child_page:ID depth=N -->\n## Title\n\n<body>\n<!-- /child_page:ID -->` for `Inlined`; single-line comment stubs for other states.
- Unit tests: `child_page_test.gleam` covers decoder + all three render states + `with_children`. Live test: `child_page_live_test.gleam` creates subpage via `parent: {page_id}`, appends body, recursively fetches with `max_depth=2`, asserts `Inlined` + non-empty children.

# Child page — create + update (write)

**Phase:** v2 / 7 of 10
**Depends on:** 21-child-page-read
**Spec:** `specs/v2-markdown-extensions.md` §6

## Goal
When appending markdown that contains `<!-- child_page:ID -->` … `<!-- /child_page:ID -->` blocks, create (if empty ID) or append to (if ID present) the subpage.

## Steps
- [x] Parse the open marker: empty ID → create new subpage via `POST /v1/pages` with `parent: { page_id: <current_page> }`, properties derived from the heading line immediately after.
- [x] Existing ID → `PATCH /v1/blocks/<id>/children` with the inner markdown.
- [x] Nested markers inside an outer block handled recursively.
- [x] Unit tests with stubbed sender: new subpage create, existing subpage append, deeply nested mix.
- [x] Live integration: create row "phase-22 child-page write", append a block of markdown with one new-subpage marker + one existing-subpage marker, re-read, assert structure.

## Done when
Markdown-driven subpage creation works; re-reading shows the new subpage with expected content.

## Notes
- Segmentation lives in `markdown.gleam` as pure `segment_markdown(md) -> List(WriteSegment)`. Variants: `PlainMarkdown(md)`, `CreateSubpage(title, body)`, `AppendSubpage(id, body)`.
- Open marker parser accepts `<!-- child_page:ID ... -->` and extracts only the first token after `:` as the ID (so `depth=N` trailing metadata is ignored).
- `""` and `new` both map to CreateSubpage; any other non-empty id maps to AppendSubpage.
- Title extraction: for CreateSubpage only, pop the first non-blank `## Title` line from inner lines; AppendSubpage keeps inner body verbatim (including any heading).
- Nested markers handled by depth-counting in `consume_child`; inner body preserves nested markers verbatim so recursive `segment_markdown` call on the body re-parses them.
- Dispatcher in `cli.gleam` (`apply_segments`/`apply_segment`): plain → PATCH `/v1/blocks/<parent>/children`; AppendSubpage → recurse with `id` as parent; CreateSubpage → POST `/v1/pages` with `{parent:{page_id}, properties:{title:…}}`, then recurse with returned id.
- Unit tests (`child_page_write_test.gleam`) use pure parser — no sender stub needed. Live test (`child_page_write_live_test.gleam`) mirrors the CLI dispatcher to exercise the full API path against the reference DB.

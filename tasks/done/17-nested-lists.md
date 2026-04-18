# Nested lists

**Phase:** v2 / 2 of 10
**Depends on:** 16-rich-text
**Spec:** `specs/v2-markdown-extensions.md` §2

## Goal
Preserve list nesting in both directions. 2-space indent per level, max depth 10.

## Steps
- [x] Read side: already recurses `has_children`; verify render emits 2-space indent per level and renumbers nested numbered lists from 1.
- [x] Write side: `parse_lines` currently flat. Replace with a tree builder that inspects leading-space count.
- [x] Handle tab = 4 spaces. Mixed indentation → log warning, align to detected step.
- [x] Non-list paragraph under a list item → child paragraph block.
- [x] Emit `children: [...]` on each list-item block JSON; Notion accepts nested children in `append /children`.
- [x] Unit tests: depth 3 bulleted, depth 3 numbered, mixed, paragraph under item, mixed indentation.
- [x] Live integration: create row "phase-17 nesting", append deeply nested list, re-read, assert tree shape.

## Done when
3-deep nesting round-trips losslessly; numbered renumbering correct.

## Notes
- Tree builder: `consume_list_loop` consumes sibling list items at same level, recurses on deeper indent, flushes on shallower. Non-list indented content attaches as child paragraph.
- Tab = 4 spaces in `count_indent`. Depth capped at level 10 via `int.min(indent_chars / 2, 10)`; mixed indentation rounds down (no explicit warning log — spec deferred).
- Only emits `"children":[...]` key when non-empty (keeps flat-list JSON clean).
- 14 new unit tests in `nested_lists_test.gleam` + 1 live round-trip in `nested_lists_live_test.gleam`. 111 total pass (was 97).

# Nested lists

**Phase:** v2 / 2 of 10
**Depends on:** 16-rich-text
**Spec:** `specs/v2-markdown-extensions.md` §2

## Goal
Preserve list nesting in both directions. 2-space indent per level, max depth 10.

## Steps
- [ ] Read side: already recurses `has_children`; verify render emits 2-space indent per level and renumbers nested numbered lists from 1.
- [ ] Write side: `parse_lines` currently flat. Replace with a tree builder that inspects leading-space count.
- [ ] Handle tab = 4 spaces. Mixed indentation → log warning, align to detected step.
- [ ] Non-list paragraph under a list item → child paragraph block.
- [ ] Emit `children: [...]` on each list-item block JSON; Notion accepts nested children in `append /children`.
- [ ] Unit tests: depth 3 bulleted, depth 3 numbered, mixed, paragraph under item, mixed indentation.
- [ ] Live integration: create row "phase-17 nesting", append deeply nested list, re-read, assert tree shape.

## Done when
3-deep nesting round-trips losslessly; numbered renumbering correct.

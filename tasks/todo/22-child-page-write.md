# Child page — create + update (write)

**Phase:** v2 / 7 of 10
**Depends on:** 21-child-page-read
**Spec:** `specs/v2-markdown-extensions.md` §6

## Goal
When appending markdown that contains `<!-- child_page:ID -->` … `<!-- /child_page:ID -->` blocks, create (if empty ID) or append to (if ID present) the subpage.

## Steps
- [ ] Parse the open marker: empty ID → create new subpage via `POST /v1/pages` with `parent: { page_id: <current_page> }`, properties derived from the heading line immediately after.
- [ ] Existing ID → `PATCH /v1/blocks/<id>/children` with the inner markdown.
- [ ] Nested markers inside an outer block handled recursively.
- [ ] Unit tests with stubbed sender: new subpage create, existing subpage append, deeply nested mix.
- [ ] Live integration: create row "phase-22 child-page write", append a block of markdown with one new-subpage marker + one existing-subpage marker, re-read, assert structure.

## Done when
Markdown-driven subpage creation works; re-reading shows the new subpage with expected content.

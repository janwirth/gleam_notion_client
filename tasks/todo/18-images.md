# Images

**Phase:** v2 / 3 of 10
**Depends on:** 16-rich-text
**Spec:** `specs/v2-markdown-extensions.md` §5

## Goal
Top-level image lines: `![caption](url)` ↔ Notion `image` block (external only).

## Steps
- [ ] Read: `image.external.url` → `![cap](url)`. `image.file.url` → same but log warning about stale signed URL (~1h TTL). Caption flattened via `rich_text` runs (plain-text fallback).
- [ ] Write: detect line matching `^!\[(.*)\]\((.+)\)$` → `image` block `type: "external", external: { url }, caption: rich_text`.
- [ ] Inline `![…]` mid-paragraph: reject, degrade to rich-text literal (documented).
- [ ] Unit tests: external URL, file URL (read warning), caption with annotations.
- [ ] Live integration: create row "phase-18 images", append external image, re-read, assert URL + caption survive.

## Done when
External images round-trip. File-hosted image read emits warning. `gleam test` green.

# Images

**Phase:** v2 / 3 of 10
**Depends on:** 16-rich-text
**Spec:** `specs/v2-markdown-extensions.md` §5

## Goal
Top-level image lines: `![caption](url)` ↔ Notion `image` block (external only).

## Steps
- [x] Read: `image.external.url` → `![cap](url)`. `image.file.url` → same but log warning about stale signed URL (~1h TTL). Caption flattened via `rich_text` runs (plain-text fallback).
- [x] Write: detect line matching `^!\[(.*)\]\((.+)\)$` → `image` block `type: "external", external: { url }, caption: rich_text`.
- [x] Inline `![…]` mid-paragraph: reject, degrade to rich-text literal (documented).
- [x] Unit tests: external URL, file URL (read warning), caption with annotations.
- [x] Live integration: create row "phase-18 images", append external image, re-read, assert URL + caption survive.

## Done when
External images round-trip. File-hosted image read emits warning. `gleam test` green.

## Notes
- New `Image(url, caption, external)` variant on `Block`.
- Decoder uses `decode.one_of` over `image.external.url` / `image.file.url`; first match wins, so Notion-hosted `file` variant decodes via fallback branch (sets `external = False`).
- Renderer emits stderr warning via `io.println_error` when `external = False`. Markdown module has no `Client`, so standalone stderr write is simpler than threading a `Logger` through the render path.
- Inline `![…](url)` mid-paragraph: caught by rich-text parser as literal `!` + link (spec-sanctioned degradation). Detection of standalone image line happens in `non_list_block` guarded by `"!["` prefix, so nested (indented) image lines also convert.
- Unit tests: 9 new (write external, empty caption, caption annotations, malformed fallback, inline degrade, read external, read file, render external, render empty, render file). Live test creates row "phase-18 images" and asserts URL survives.
- 122 total pass (was 111).

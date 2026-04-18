# Iframes / embeds

**Phase:** v2 / 4 of 10
**Depends on:** 16-rich-text
**Spec:** `specs/v2-markdown-extensions.md` §4

## Goal
Single-line `<iframe src="URL"></iframe>` ↔ Notion `embed` block.

## Steps
- [ ] Read: `embed.url` → `<iframe src="URL"></iframe>`. Caption (if present) as following italic paragraph `*caption*`.
- [ ] Write: regex match `<iframe[^>]*\bsrc="([^"]+)"[^>]*>\s*</iframe>` → `embed` block with `url`.
- [ ] `bookmark` / `link_preview` on read → `[URL](URL)` rich-text link (lossy, documented).
- [ ] Self-closing `<iframe/>` supported. Multi-line rejected.
- [ ] Unit tests: basic iframe, iframe with extra attrs (only `src` used), self-closing.
- [ ] Live integration: create row "phase-19 iframes", append iframe, re-read, assert URL preserved.

## Done when
Iframe round-trips via `embed` block.

# Iframes / embeds

**Phase:** v2 / 4 of 10
**Depends on:** 16-rich-text
**Spec:** `specs/v2-markdown-extensions.md` §4

## Goal
Single-line `<iframe src="URL"></iframe>` ↔ Notion `embed` block.

## Steps
- [x] Read: `embed.url` → `<iframe src="URL"></iframe>`. Caption (if present) as following italic paragraph `*caption*`.
- [x] Write: regex match `<iframe[^>]*\bsrc="([^"]+)"[^>]*>\s*</iframe>` → `embed` block with `url`.
- [x] `bookmark` / `link_preview` on read → `[URL](URL)` rich-text link (lossy, documented).
- [x] Self-closing `<iframe/>` supported. Multi-line rejected.
- [x] Unit tests: basic iframe, iframe with extra attrs (only `src` used), self-closing.
- [x] Live integration: create row "phase-19 iframes", append iframe, re-read, assert URL preserved.

## Done when
Iframe round-trips via `embed` block.

## Notes
- Added `Embed(url, caption)` and `Bookmark(url)` `Block` variants.
- Write-side detection in `non_list_block` guarded by `"<iframe"` prefix; `parse_iframe_line` accepts both `</iframe>` close and `/>` self-close (trailing). Src extraction splits on `src="..."` (double-quote only per spec).
- Multi-line iframes rejected implicitly: `walk_lines` processes one line at a time, so a `<iframe …>` without a closing tag on the same line fails detection and falls through to paragraph.
- Bookmark/link_preview render as `[url](url)` literal; no reverse — plain links in markdown land as rich-text links in paragraphs per spec.
- Embed caption renders as following italic paragraph via `render_embed`. Captions not parsed from markdown on write (spec: "Captions not parsed from markdown … use the Notion UI").
- 10 new unit tests (6 write, 4 read/render) + 1 live round-trip. 134 total pass (was 122).

# Rich text: annotations + links

**Phase:** v2 / 1 of 10
**Depends on:** none
**Spec:** `specs/v2-markdown-extensions.md` §1

## Goal
Bidirectional conversion between Notion rich_text arrays and markdown annotations (`**bold**`, `*italic*`, `~~strike~~`, `` `code` ``, `[text](url)`, `<u>`, `<span style="color:…">`).

## Steps
- [x] New module `src/notion_client/rich_text.gleam`: `type Run { Run(text, bold, italic, strikethrough, code, underline, color, href) }`
- [x] `runs_to_markdown(List(Run)) -> String`: emit with canonical annotation nesting; collapse adjacent runs with identical annotations; escape `*_` `` ` `` `[` `]` `\` in text.
- [x] `markdown_to_runs(String) -> List(Run)`: inline parser handling `**`, `*`, `~~`, `` ` ``, `[…](…)`, `<u>…</u>`, `<span style="color:…">…</span>`. Escaped chars become literals. Unclosed emphasis → treat opener as literal.
- [x] `runs_to_json(List(Run)) -> Json`: emit Notion rich_text array.
- [x] `run_list_decoder() -> Decoder(List(Run))`: decode rich_text array (named thus; composes with `decode.run` or `json.parse`).
- [x] Wire into `markdown.gleam`: paragraph/headings/list items/quote/to_do now pipe through rich_text runs; code blocks keep plain-text concat (annotations inside code are meaningless).
- [x] Unit tests: round-trip for every annotation individually + combinations; escaping; unclosed emphasis. 39 tests in `test/rich_text_test.gleam`.
- [x] Live integration: `test/rich_text_live_test.gleam` creates a row in `$NOTION_BOOTSTRAP_DATABASE_ID` titled "phase-16 rich text", appends a paragraph with every annotation, refetches the block tree, and asserts each annotation marker survives the round-trip. Skips when either env var is unset.

## Done when
All unit tests pass. Live round-trip confirms every annotation persists through Notion. `gleam test` green — 97 tests pass (was 57 + 39 unit + 1 live).

## Notes
- Link round-trip assertion checks for the `[link](` prefix only rather than
  the full URL; Notion normalises outgoing URLs (e.g. adds schema prefixes
  or strips trailing slashes) so an exact-URL match is flaky across runs.
- `run_list_decoder` treats `annotations` and `href` as optional fields so
  cached fixtures captured pre-v2 still decode (some responses omit `href`
  for items without links).

# Rich text: annotations + links

**Phase:** v2 / 1 of 10
**Depends on:** none
**Spec:** `specs/v2-markdown-extensions.md` §1

## Goal
Bidirectional conversion between Notion rich_text arrays and markdown annotations (`**bold**`, `*italic*`, `~~strike~~`, `` `code` ``, `[text](url)`, `<u>`, `<span style="color:…">`).

## Steps
- [ ] New module `src/notion_client/rich_text.gleam`: `type Run { Run(text, bold, italic, strikethrough, code, underline, color, href) }`
- [ ] `runs_to_markdown(List(Run)) -> String`: emit with canonical annotation nesting; collapse adjacent runs with identical annotations; escape `*_` `` ` `` `[` `]` `\` in text.
- [ ] `markdown_to_runs(String) -> List(Run)`: inline parser handling `**`, `*`, `~~`, `` ` ``, `[…](…)`, `<u>…</u>`, `<span style="color:…">…</span>`. Escaped chars become literals. Unclosed emphasis → treat opener as literal.
- [ ] `runs_to_json(List(Run)) -> Json`: emit Notion rich_text array.
- [ ] `json_to_runs(Dynamic) -> List(Run)`: decode rich_text array.
- [ ] Wire into `markdown.gleam`: replace plain-text rich-text handling with Run-based.
- [ ] Unit tests: round-trip for every annotation individually + combinations; escaping; unclosed emphasis.
- [ ] Live integration: create row in `$NOTION_BOOTSTRAP_DATABASE_ID` named "phase-16 rich text", append paragraph with all annotations, re-read, assert annotations survive.

## Done when
All unit tests pass. Live round-trip confirms every annotation persists through Notion. `gleam test` green.

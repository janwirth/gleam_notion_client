# Tables

**Phase:** v2 / 5 of 10
**Depends on:** 16-rich-text
**Spec:** `specs/v2-markdown-extensions.md` §3

## Goal
GFM tables ↔ Notion `table` + `table_row` blocks.

## Steps
- [ ] Read: table block has children = table_rows. For each row, emit `| c1 | c2 | ... |` with pipe escaped as `\|` inside cells. Second line = separator `| --- | --- |`; if `has_row_header`, first column becomes `| :--- |`. Cells use rich-text runs.
- [ ] Write: detect 3+ consecutive lines where line 2 matches `^\|[-: ]+(\|[-: ]+)+\|?$`. Parse header from line 1, alignment from line 2, rows after. Split on `|` rejecting empty outer segments. Mismatched column counts → pad with empty cells.
- [ ] Emit `table` block with `table_width`, `has_column_header: true`, `has_row_header` from alignment detection, `children: [table_row, ...]`.
- [ ] Cell content = Run-array via rich-text write path.
- [ ] Unit tests: 2x2 table, pipe escape, left-align (row header hint), mismatched row width.
- [ ] Live integration: create row "phase-20 tables", append table, re-read, assert cells + header flags.

## Done when
GFM tables round-trip; row-header hint survives via left-align.

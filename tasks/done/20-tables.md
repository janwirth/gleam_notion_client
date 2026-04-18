# Tables

**Phase:** v2 / 5 of 10
**Depends on:** 16-rich-text
**Spec:** `specs/v2-markdown-extensions.md` §3

## Goal
GFM tables ↔ Notion `table` + `table_row` blocks.

## Steps
- [x] Read: table block has children = table_rows. For each row, emit `| c1 | c2 | ... |` with pipe escaped as `\|` inside cells. Second line = separator `| --- | --- |`; if `has_row_header`, first column becomes `| :--- |`. Cells use rich-text runs.
- [x] Write: detect 3+ consecutive lines where line 2 matches `^\|[-: ]+(\|[-: ]+)+\|?$`. Parse header from line 1, alignment from line 2, rows after. Split on `|` rejecting empty outer segments. Mismatched column counts → pad with empty cells.
- [x] Emit `table` block with `table_width`, `has_column_header: true`, `has_row_header` from alignment detection, `children: [table_row, ...]`.
- [x] Cell content = Run-array via rich-text write path.
- [x] Unit tests: 2x2 table, pipe escape, left-align (row header hint), mismatched row width.
- [x] Live integration: create row "phase-20 tables", append table, re-read, assert cells + header flags.

## Done when
GFM tables round-trip; row-header hint survives via left-align.

## Notes
- Added `Table(rows, has_column_header, has_row_header)` + `TableRow(cells)` `Block` variants.
- `with_children` for `Table` walks children list, picks `TableRow` cells, drops other variants. Lets cli.gleam's existing recursive fetcher wire rows in without special-casing.
- Write: `walk_lines` peeks at 3 lines via `maybe_table`. Detection requires line 2 to be sep-char-only (`|`, `-`, `:`, space, tab) with at least one `|` and `-`. Row-header flag set when first column in sep row starts with `:`.
- Row splitter `split_cells` handles `\|` escapes during split; then `unescape_pipe` converts `\|` → `|` inside cells.
- Mismatched row widths: `pad_to` adds empty cells on short rows; truncates long rows to header width.
- Cell content runs through rich_text codec (bold/italic/links inside cells preserved).
- 11 new unit tests + 1 live round-trip creating "phase-20 tables". 145 total pass (was 134).

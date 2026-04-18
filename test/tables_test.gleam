//// Unit tests for phase-20 GFM table ↔ Notion `table` block.
//// Covers write detection + shape, read/render round-trip shape,
//// pipe escaping, row-header hint, and mismatched widths.

import gleam/json
import gleam/string
import gleeunit/should
import notion_client/markdown

pub fn main() {
  Nil
}

fn from(md: String) -> String {
  json.to_string(markdown.from_markdown(md))
}

// ─── write side ────────────────────────────────────────────────────────

pub fn write_basic_2x2_test() {
  let md = "| a | b |\n|---|---|\n| c | d |"
  let j = from(md)
  should.equal(string.contains(j, "\"type\":\"table\""), True)
  should.equal(string.contains(j, "\"table_width\":2"), True)
  should.equal(string.contains(j, "\"has_column_header\":true"), True)
  should.equal(string.contains(j, "\"has_row_header\":false"), True)
  // Two table_row blocks (header + body row).
  let row_count = list_count(string.split(j, "\"type\":\"table_row\""))
  should.equal(row_count, 3)
  // Both header and body cells present.
  should.equal(string.contains(j, "\"content\":\"a\""), True)
  should.equal(string.contains(j, "\"content\":\"d\""), True)
}

// Count segments = count("foo", "X") pieces - 1.
fn list_count(segments: List(String)) -> Int {
  case segments {
    [] -> 0
    [_, ..rest] -> 1 + list_count(rest)
  }
}

pub fn write_pipe_escape_test() {
  // Cell content contains literal `|` (escaped as `\|`).
  let md = "| a | b\\|c |\n|---|---|\n| x | y |"
  let j = from(md)
  should.equal(string.contains(j, "\"type\":\"table\""), True)
  // Unescaped `|` should appear in cell content.
  should.equal(string.contains(j, "\"content\":\"b|c\""), True)
}

pub fn write_row_header_left_align_test() {
  let md = "| a | b |\n| :--- | --- |\n| c | d |"
  let j = from(md)
  should.equal(string.contains(j, "\"has_row_header\":true"), True)
}

pub fn write_mismatched_row_width_padded_test() {
  // Body row has only 1 cell; pad to width 2 with empty string.
  let md = "| a | b |\n|---|---|\n| c |"
  let j = from(md)
  should.equal(string.contains(j, "\"type\":\"table\""), True)
  should.equal(string.contains(j, "\"table_width\":2"), True)
  // Two body cells for the row: `c` then empty.
  should.equal(string.contains(j, "\"content\":\"c\""), True)
}

pub fn write_no_separator_is_paragraph_test() {
  // Missing separator line → not a table, falls through.
  let md = "| a | b |\n| c | d |"
  let j = from(md)
  should.equal(string.contains(j, "\"type\":\"table\""), False)
  should.equal(string.contains(j, "\"type\":\"paragraph\""), True)
}

pub fn write_table_then_paragraph_test() {
  let md = "| a | b |\n|---|---|\n| c | d |\n\nafter"
  let j = from(md)
  should.equal(string.contains(j, "\"type\":\"table\""), True)
  should.equal(string.contains(j, "\"type\":\"paragraph\""), True)
  // Paragraph content is "after".
  should.equal(string.contains(j, "\"content\":\"after\""), True)
}

// ─── read / render ─────────────────────────────────────────────────────

pub fn render_2x2_test() {
  let table = markdown.Table([["h1", "h2"], ["a", "b"]], True, False)
  let out = markdown.to_markdown([table])
  should.equal(out, "| h1 | h2 |\n| --- | --- |\n| a | b |")
}

pub fn render_row_header_test() {
  let table = markdown.Table([["h1", "h2"], ["a", "b"]], True, True)
  let out = markdown.to_markdown([table])
  should.equal(out, "| h1 | h2 |\n| :--- | --- |\n| a | b |")
}

pub fn render_pipe_escape_test() {
  let table = markdown.Table([["a", "b|c"]], True, False)
  let out = markdown.to_markdown([table])
  should.equal(out, "| a | b\\|c |\n| --- | --- |")
}

pub fn with_children_table_test() {
  let parent = markdown.Table([], True, False)
  let kids = [
    markdown.TableRow(["h1", "h2"]),
    markdown.TableRow(["a", "b"]),
  ]
  let merged = markdown.with_children(parent, kids)
  should.equal(merged, markdown.Table([["h1", "h2"], ["a", "b"]], True, False))
}

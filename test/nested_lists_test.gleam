//// Unit tests for nested list handling in `notion_client/markdown`.
//// Covers the markdown→Notion JSON tree builder and the Notion→markdown
//// renderer's indent + numbered-restart behaviour.

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

/// Strip the outer `{"children":[...]}` wrapper so tests can reason about
/// block-level JSON without confusing matches on the envelope key.
fn inner(md: String) -> String {
  let full = from(md)
  case string.split_once(full, "{\"children\":[") {
    Ok(#(_, rest)) ->
      case string.length(rest) >= 2 {
        True -> string.drop_end(rest, 2)
        False -> rest
      }
    Error(_) -> full
  }
}

// ─── write side: nested JSON ────────────────────────────────────────────

pub fn flat_bullets_test() {
  let j = inner("- a\n- b")
  should.equal(string.contains(j, "\"type\":\"bulleted_list_item\""), True)
  // No nested `children` on flat items.
  should.equal(string.contains(j, "\"children\":["), False)
}

pub fn two_level_bullets_test() {
  let j = inner("- parent\n  - child")
  // Parent carries a `children` array with the nested bullet.
  should.equal(string.contains(j, "\"children\":["), True)
  should.equal(string.contains(j, "\"type\":\"bulleted_list_item\""), True)
}

pub fn three_level_bullets_test() {
  let j = inner("- a\n  - b\n    - c")
  // Two levels of `children` arrays nested inside bulleted_list_item.
  let first = case string.split_once(j, "\"children\":[") {
    Ok(#(_, rest)) -> rest
    Error(_) -> ""
  }
  should.equal(string.contains(first, "\"children\":["), True)
}

pub fn tab_counts_as_four_spaces_test() {
  let j = inner("- a\n\t- b")
  should.equal(string.contains(j, "\"children\":["), True)
}

pub fn numbered_nested_under_bullet_test() {
  let j = inner("- outer\n  1. inner")
  should.equal(string.contains(j, "\"children\":["), True)
  should.equal(string.contains(j, "\"numbered_list_item\""), True)
}

pub fn paragraph_child_of_list_item_test() {
  let j = inner("- item\n  continuation paragraph")
  should.equal(string.contains(j, "\"children\":["), True)
  should.equal(string.contains(j, "\"type\":\"paragraph\""), True)
}

pub fn todo_nested_test() {
  let j = inner("- [ ] outer\n  - [x] inner")
  should.equal(string.contains(j, "\"to_do\""), True)
  should.equal(string.contains(j, "\"checked\":true"), True)
  should.equal(string.contains(j, "\"checked\":false"), True)
}

pub fn orphan_nested_becomes_top_level_test() {
  let j = inner("  - orphan")
  should.equal(string.contains(j, "\"bulleted_list_item\""), True)
}

pub fn non_list_line_breaks_list_test() {
  let j = inner("- item\n\n# heading")
  should.equal(string.contains(j, "\"heading_1\""), True)
  // Heading is a sibling block, not nested under the bullet — no `children`
  // array appears before the heading's envelope.
  case string.split_once(j, "\"heading_1\"") {
    Ok(#(before, _)) ->
      should.equal(string.contains(before, "\"children\":["), False)
    Error(_) -> panic as "heading_1 not emitted"
  }
}

// ─── read side: render indent + numbered restart ────────────────────────

pub fn render_flat_bullets_test() {
  let blocks = [
    markdown.BulletedListItem("a", []),
    markdown.BulletedListItem("b", []),
  ]
  should.equal(markdown.to_markdown(blocks), "- a\n- b")
}

pub fn render_nested_bullets_test() {
  let blocks = [
    markdown.BulletedListItem("parent", [markdown.BulletedListItem("child", [])]),
  ]
  should.equal(markdown.to_markdown(blocks), "- parent\n  - child")
}

pub fn render_numbered_restart_at_nested_level_test() {
  let blocks = [
    markdown.NumberedListItem("a", [
      markdown.NumberedListItem("nested-a", []),
      markdown.NumberedListItem("nested-b", []),
    ]),
    markdown.NumberedListItem("b", []),
  ]
  let rendered = markdown.to_markdown(blocks)
  // Nested numbered children restart at 1; outer continues at 2.
  should.equal(rendered, "1. a\n  1. nested-a\n  2. nested-b\n2. b")
}

pub fn render_three_level_indent_test() {
  let blocks = [
    markdown.BulletedListItem("a", [
      markdown.BulletedListItem("b", [markdown.BulletedListItem("c", [])]),
    ]),
  ]
  should.equal(markdown.to_markdown(blocks), "- a\n  - b\n    - c")
}

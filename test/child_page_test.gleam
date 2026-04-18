//// Unit tests for phase-21 child_page / child_database rendering +
//// decoding. Covers inlined render, depth-limit stub, cycle stub,
//// child_database stub, and decoder shape.

import gleam/json
import gleeunit/should
import notion_client/markdown

pub fn main() {
  Nil
}

fn parse_block(j: String) -> markdown.Block {
  let assert Ok(b) = json.parse(j, markdown.block_decoder())
  b
}

// ─── decoder ───────────────────────────────────────────────────────────

pub fn read_child_page_test() {
  let b =
    parse_block(
      "{\"type\":\"child_page\",\"id\":\"abc123\","
      <> "\"child_page\":{\"title\":\"Sub Page\"}}",
    )
  should.equal(
    b,
    markdown.ChildPage("abc123", "Sub Page", 0, [], markdown.Inlined),
  )
}

pub fn read_child_database_test() {
  let b =
    parse_block(
      "{\"type\":\"child_database\",\"id\":\"db1\","
      <> "\"child_database\":{\"title\":\"My DB\"}}",
    )
  should.equal(b, markdown.ChildDatabase("db1", "My DB"))
}

// ─── render ────────────────────────────────────────────────────────────

pub fn render_child_page_empty_test() {
  let cp = markdown.ChildPage("abc", "Title", 1, [], markdown.Inlined)
  let out = markdown.to_markdown([cp])
  should.equal(
    out,
    "<!-- child_page:abc depth=1 -->\n## Title\n<!-- /child_page:abc -->",
  )
}

pub fn render_child_page_with_body_test() {
  let kids = [markdown.Paragraph("hello", [])]
  let cp = markdown.ChildPage("abc", "Title", 2, kids, markdown.Inlined)
  let out = markdown.to_markdown([cp])
  should.equal(
    out,
    "<!-- child_page:abc depth=2 -->\n## Title\n\nhello\n<!-- /child_page:abc -->",
  )
}

pub fn render_child_page_depth_limit_test() {
  let cp = markdown.ChildPage("abc", "Title", 3, [], markdown.DepthLimitReached)
  let out = markdown.to_markdown([cp])
  should.equal(out, "<!-- child_page:abc (depth limit) -->")
}

pub fn render_child_page_cycle_test() {
  let cp = markdown.ChildPage("abc", "Title", 1, [], markdown.CycleDetected)
  let out = markdown.to_markdown([cp])
  should.equal(out, "<!-- child_page:abc (cycle) -->")
}

pub fn render_child_database_test() {
  let cd = markdown.ChildDatabase("db1", "My DB")
  let out = markdown.to_markdown([cd])
  should.equal(out, "<!-- child_database:db1 title=\"My DB\" -->")
}

// ─── with_children ─────────────────────────────────────────────────────

pub fn with_children_child_page_test() {
  let parent = markdown.ChildPage("abc", "Title", 1, [], markdown.Inlined)
  let kids = [markdown.Paragraph("hi", [])]
  let merged = markdown.with_children(parent, kids)
  should.equal(
    merged,
    markdown.ChildPage("abc", "Title", 1, kids, markdown.Inlined),
  )
}

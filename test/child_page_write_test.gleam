//// Unit tests for phase-22 child_page write segmentation. Covers the
//// pure `segment_markdown` parser: create vs append classification,
//// title extraction, plain interleaving, and nested markers.

import gleeunit/should
import notion_client/markdown

pub fn main() {
  Nil
}

pub fn plain_only_test() {
  let segs = markdown.segment_markdown("hello\nworld")
  should.equal(segs, [markdown.PlainMarkdown("hello\nworld")])
}

pub fn create_empty_id_test() {
  let md = "<!-- child_page: -->\n## Title\n\nhello\n<!-- /child_page: -->"
  let segs = markdown.segment_markdown(md)
  should.equal(segs, [markdown.CreateSubpage("Title", "\nhello")])
}

pub fn create_new_id_test() {
  let md = "<!-- child_page:new -->\n## T\nbody\n<!-- /child_page:new -->"
  let segs = markdown.segment_markdown(md)
  should.equal(segs, [markdown.CreateSubpage("T", "body")])
}

pub fn append_existing_id_test() {
  let md =
    "<!-- child_page:abc123 depth=1 -->\n## T\nhi\n<!-- /child_page:abc123 -->"
  let segs = markdown.segment_markdown(md)
  should.equal(segs, [markdown.AppendSubpage("abc123", "## T\nhi")])
}

pub fn plain_before_and_after_test() {
  let md =
    "before\n<!-- child_page:new -->\n## T\nx\n<!-- /child_page:new -->\nafter"
  let segs = markdown.segment_markdown(md)
  should.equal(segs, [
    markdown.PlainMarkdown("before"),
    markdown.CreateSubpage("T", "x"),
    markdown.PlainMarkdown("after"),
  ])
}

pub fn nested_markers_preserved_test() {
  // Outer is create; inner marker survives in body, to be re-segmented
  // on recursive apply.
  let md =
    "<!-- child_page:new -->\n## Outer\n"
    <> "<!-- child_page:new -->\n## Inner\nx\n<!-- /child_page:new -->\n"
    <> "<!-- /child_page:new -->"
  let segs = markdown.segment_markdown(md)
  should.equal(segs, [
    markdown.CreateSubpage(
      "Outer",
      "<!-- child_page:new -->\n## Inner\nx\n<!-- /child_page:new -->",
    ),
  ])
  // Recursively re-segment the inner body to verify nested handling.
  let assert [markdown.CreateSubpage(_, body)] = segs
  should.equal(markdown.segment_markdown(body), [
    markdown.CreateSubpage("Inner", "x"),
  ])
}

pub fn append_no_title_heading_test() {
  let md = "<!-- child_page:id1 -->\nplain text\n<!-- /child_page:id1 -->"
  let segs = markdown.segment_markdown(md)
  should.equal(segs, [markdown.AppendSubpage("id1", "plain text")])
}

pub fn empty_string_test() {
  should.equal(markdown.segment_markdown(""), [])
}

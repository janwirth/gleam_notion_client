//// Unit tests for phase-18 image block round-trip. Covers
//// markdown→Notion JSON write path, the Notion→markdown renderer, and
//// the external/file URL branch.

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

pub fn write_external_image_test() {
  let j = from("![alt](https://example.com/x.png)")
  should.equal(string.contains(j, "\"type\":\"image\""), True)
  should.equal(string.contains(j, "\"external\":{"), True)
  should.equal(
    string.contains(j, "\"url\":\"https://example.com/x.png\""),
    True,
  )
  // Caption present in rich_text.
  should.equal(string.contains(j, "\"caption\":["), True)
  should.equal(string.contains(j, "\"content\":\"alt\""), True)
}

pub fn write_image_empty_caption_test() {
  let j = from("![](https://example.com/y.png)")
  should.equal(string.contains(j, "\"type\":\"image\""), True)
  should.equal(string.contains(j, "\"caption\":[]"), True)
}

pub fn write_image_caption_with_annotations_test() {
  let j = from("![**bold** cap](https://example.com/z.png)")
  should.equal(string.contains(j, "\"type\":\"image\""), True)
  should.equal(string.contains(j, "\"bold\":true"), True)
}

pub fn write_malformed_image_is_paragraph_test() {
  // No closing paren → falls back to paragraph.
  let j = from("![alt](https://example.com/x.png")
  should.equal(string.contains(j, "\"type\":\"image\""), False)
  should.equal(string.contains(j, "\"type\":\"paragraph\""), True)
}

pub fn inline_image_degrades_to_paragraph_test() {
  // `![…]` mid-paragraph: not a top-level image line.
  let j = from("text before ![inline](https://example.com/x.png) after")
  should.equal(string.contains(j, "\"type\":\"image\""), False)
  should.equal(string.contains(j, "\"type\":\"paragraph\""), True)
}

// ─── read side ─────────────────────────────────────────────────────────

fn parse_block(j: String) -> markdown.Block {
  let assert Ok(b) = json.parse(j, markdown.block_decoder())
  b
}

pub fn read_external_image_test() {
  let b =
    parse_block(
      "{\"type\":\"image\",\"image\":{\"type\":\"external\","
      <> "\"external\":{\"url\":\"https://example.com/x.png\"},"
      <> "\"caption\":[{\"type\":\"text\",\"plain_text\":\"alt\","
      <> "\"text\":{\"content\":\"alt\"},"
      <> "\"annotations\":{\"bold\":false,\"italic\":false,"
      <> "\"strikethrough\":false,\"underline\":false,\"code\":false,"
      <> "\"color\":\"default\"}}]}}",
    )
  should.equal(b, markdown.Image("https://example.com/x.png", "alt", True))
}

pub fn read_file_image_test() {
  let b =
    parse_block(
      "{\"type\":\"image\",\"image\":{\"type\":\"file\","
      <> "\"file\":{\"url\":\"https://s3/x.png?sig=1\"},"
      <> "\"caption\":[]}}",
    )
  should.equal(b, markdown.Image("https://s3/x.png?sig=1", "", False))
}

pub fn render_external_image_test() {
  let rendered =
    markdown.to_markdown([
      markdown.Image("https://example.com/x.png", "cap", True),
    ])
  should.equal(rendered, "![cap](https://example.com/x.png)")
}

pub fn render_image_empty_caption_test() {
  let rendered =
    markdown.to_markdown([markdown.Image("https://example.com/x.png", "", True)])
  should.equal(rendered, "![](https://example.com/x.png)")
}

pub fn render_file_image_test() {
  // File-hosted still renders; emits stderr warning (not asserted here).
  let rendered =
    markdown.to_markdown([
      markdown.Image("https://s3/x.png?sig=1", "alt", False),
    ])
  should.equal(rendered, "![alt](https://s3/x.png?sig=1)")
}

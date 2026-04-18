//// Unit tests for phase-19 iframe/embed block. Covers markdown→Notion
//// write path, Notion→markdown render, bookmark/link_preview read
//// degradation, and self-closing iframe acceptance.

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

pub fn write_basic_iframe_test() {
  let j = from("<iframe src=\"https://example.com/w\"></iframe>")
  should.equal(string.contains(j, "\"type\":\"embed\""), True)
  should.equal(string.contains(j, "\"url\":\"https://example.com/w\""), True)
}

pub fn write_iframe_with_extra_attrs_test() {
  let j =
    from(
      "<iframe width=\"600\" src=\"https://example.com/w\" height=\"400\"></iframe>",
    )
  should.equal(string.contains(j, "\"type\":\"embed\""), True)
  should.equal(string.contains(j, "\"url\":\"https://example.com/w\""), True)
}

pub fn write_self_closing_iframe_test() {
  let j = from("<iframe src=\"https://example.com/w\"/>")
  should.equal(string.contains(j, "\"type\":\"embed\""), True)
  should.equal(string.contains(j, "\"url\":\"https://example.com/w\""), True)
}

pub fn write_multiline_iframe_rejected_test() {
  // Line 1 has no close tag, so detection fails and it falls through to
  // paragraph. Line 2 is a separate block.
  let j = from("<iframe src=\"https://example.com/w\">\n</iframe>")
  should.equal(string.contains(j, "\"type\":\"embed\""), False)
  should.equal(string.contains(j, "\"type\":\"paragraph\""), True)
}

pub fn write_malformed_iframe_falls_back_test() {
  // Missing `src=` → paragraph.
  let j = from("<iframe></iframe>")
  should.equal(string.contains(j, "\"type\":\"embed\""), False)
  should.equal(string.contains(j, "\"type\":\"paragraph\""), True)
}

// ─── read side ─────────────────────────────────────────────────────────

fn parse_block(j: String) -> markdown.Block {
  let assert Ok(b) = json.parse(j, markdown.block_decoder())
  b
}

pub fn read_embed_test() {
  let b =
    parse_block(
      "{\"type\":\"embed\",\"embed\":{\"url\":\"https://example.com/w\","
      <> "\"caption\":[]}}",
    )
  should.equal(b, markdown.Embed("https://example.com/w", ""))
}

pub fn render_embed_test() {
  let rendered =
    markdown.to_markdown([markdown.Embed("https://example.com/w", "")])
  should.equal(rendered, "<iframe src=\"https://example.com/w\"></iframe>")
}

pub fn render_embed_with_caption_test() {
  let rendered =
    markdown.to_markdown([markdown.Embed("https://example.com/w", "hello")])
  should.equal(
    rendered,
    "<iframe src=\"https://example.com/w\"></iframe>\n*hello*",
  )
}

pub fn read_bookmark_test() {
  let b =
    parse_block(
      "{\"type\":\"bookmark\",\"bookmark\":{\"url\":\"https://example.com/b\"}}",
    )
  should.equal(b, markdown.Bookmark("https://example.com/b"))
}

pub fn read_link_preview_test() {
  let b =
    parse_block(
      "{\"type\":\"link_preview\",\"link_preview\":{\"url\":\"https://example.com/p\"}}",
    )
  should.equal(b, markdown.Bookmark("https://example.com/p"))
}

pub fn render_bookmark_test() {
  let rendered =
    markdown.to_markdown([markdown.Bookmark("https://example.com/b")])
  should.equal(rendered, "[https://example.com/b](https://example.com/b)")
}

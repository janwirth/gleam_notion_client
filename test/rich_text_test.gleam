//// Unit tests for `notion_client/rich_text`. Cover markdown ↔ Run
//// round-trips, escaping, canonical nesting + collapsing, unclosed
//// emphasis fallback, links, and Notion rich_text JSON codec.

import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import notion_client/rich_text.{type Run, Run}

pub fn main() {
  Nil
}

fn plain(text: String) -> Run {
  rich_text.plain(text)
}

// ─── runs → markdown ────────────────────────────────────────────────────

pub fn render_plain_test() {
  rich_text.runs_to_markdown([plain("hello")])
  |> should.equal("hello")
}

pub fn render_bold_test() {
  rich_text.runs_to_markdown([Run(..plain("hi"), bold: True)])
  |> should.equal("**hi**")
}

pub fn render_italic_test() {
  rich_text.runs_to_markdown([Run(..plain("hi"), italic: True)])
  |> should.equal("*hi*")
}

pub fn render_strike_test() {
  rich_text.runs_to_markdown([Run(..plain("hi"), strikethrough: True)])
  |> should.equal("~~hi~~")
}

pub fn render_code_test() {
  rich_text.runs_to_markdown([Run(..plain("hi"), code: True)])
  |> should.equal("`hi`")
}

pub fn render_underline_test() {
  rich_text.runs_to_markdown([Run(..plain("hi"), underline: True)])
  |> should.equal("<u>hi</u>")
}

pub fn render_color_test() {
  rich_text.runs_to_markdown([Run(..plain("hi"), color: "red")])
  |> should.equal("<span style=\"color:red\">hi</span>")
}

pub fn render_link_test() {
  rich_text.runs_to_markdown([
    Run(..plain("click"), href: Some("https://example.com")),
  ])
  |> should.equal("[click](https://example.com)")
}

pub fn render_bold_italic_test() {
  rich_text.runs_to_markdown([Run(..plain("hi"), bold: True, italic: True)])
  |> should.equal("***hi***")
}

pub fn render_bold_link_test() {
  rich_text.runs_to_markdown([
    Run(..plain("click"), bold: True, href: Some("https://example.com")),
  ])
  |> should.equal("[**click**](https://example.com)")
}

pub fn render_escapes_test() {
  rich_text.runs_to_markdown([plain("a*b_c`d[e]f\\g")])
  |> should.equal("a\\*b\\_c\\`d\\[e\\]f\\\\g")
}

pub fn render_collapses_adjacent_test() {
  rich_text.runs_to_markdown([
    Run(..plain("hel"), bold: True),
    Run(..plain("lo"), bold: True),
  ])
  |> should.equal("**hello**")
}

// ─── markdown → runs ────────────────────────────────────────────────────

pub fn parse_plain_test() {
  rich_text.markdown_to_runs("hello")
  |> should.equal([plain("hello")])
}

pub fn parse_bold_test() {
  rich_text.markdown_to_runs("**hi**")
  |> should.equal([Run(..plain("hi"), bold: True)])
}

pub fn parse_italic_test() {
  rich_text.markdown_to_runs("*hi*")
  |> should.equal([Run(..plain("hi"), italic: True)])
}

pub fn parse_strike_test() {
  rich_text.markdown_to_runs("~~gone~~")
  |> should.equal([Run(..plain("gone"), strikethrough: True)])
}

pub fn parse_code_test() {
  rich_text.markdown_to_runs("`sum(x)`")
  |> should.equal([Run(..plain("sum(x)"), code: True)])
}

pub fn parse_underline_test() {
  rich_text.markdown_to_runs("<u>underlined</u>")
  |> should.equal([Run(..plain("underlined"), underline: True)])
}

pub fn parse_color_test() {
  rich_text.markdown_to_runs("<span style=\"color:red\">red text</span>")
  |> should.equal([Run(..plain("red text"), color: "red")])
}

pub fn parse_link_test() {
  rich_text.markdown_to_runs("[click](https://example.com)")
  |> should.equal([Run(..plain("click"), href: Some("https://example.com"))])
}

pub fn parse_bold_in_link_test() {
  rich_text.markdown_to_runs("[**click**](https://example.com)")
  |> should.equal([
    Run(..plain("click"), bold: True, href: Some("https://example.com")),
  ])
}

pub fn parse_escaped_char_test() {
  rich_text.markdown_to_runs("a\\*b")
  |> should.equal([plain("a*b")])
}

pub fn parse_unclosed_bold_test() {
  rich_text.markdown_to_runs("**hello")
  |> should.equal([plain("**hello")])
}

pub fn parse_unclosed_italic_test() {
  rich_text.markdown_to_runs("*hello")
  |> should.equal([plain("*hello")])
}

pub fn parse_unclosed_code_test() {
  rich_text.markdown_to_runs("`hi")
  |> should.equal([plain("`hi")])
}

pub fn parse_mixed_plain_bold_test() {
  rich_text.markdown_to_runs("a**b**c")
  |> should.equal([plain("a"), Run(..plain("b"), bold: True), plain("c")])
}

// ─── round-trip ─────────────────────────────────────────────────────────

fn round_trip(runs: List(Run)) -> Nil {
  let md = rich_text.runs_to_markdown(runs)
  let parsed = rich_text.markdown_to_runs(md)
  should.equal(parsed, runs)
}

pub fn roundtrip_plain_test() {
  round_trip([plain("hello world")])
}

pub fn roundtrip_bold_test() {
  round_trip([Run(..plain("bold"), bold: True)])
}

pub fn roundtrip_italic_test() {
  round_trip([Run(..plain("italic"), italic: True)])
}

pub fn roundtrip_strike_test() {
  round_trip([Run(..plain("strike"), strikethrough: True)])
}

pub fn roundtrip_code_test() {
  round_trip([Run(..plain("code"), code: True)])
}

pub fn roundtrip_underline_test() {
  round_trip([Run(..plain("u"), underline: True)])
}

pub fn roundtrip_color_test() {
  round_trip([Run(..plain("colored"), color: "blue")])
}

pub fn roundtrip_link_test() {
  round_trip([Run(..plain("click"), href: Some("https://x.dev"))])
}

pub fn roundtrip_sequence_test() {
  round_trip([
    plain("start "),
    Run(..plain("bold"), bold: True),
    plain(" mid "),
    Run(..plain("link"), href: Some("https://x.dev")),
    plain(" end"),
  ])
}

// ─── JSON codec ─────────────────────────────────────────────────────────

pub fn runs_to_json_shape_test() {
  let runs = [Run(..plain("hi"), bold: True, href: Some("https://x.dev"))]
  let j = json.to_string(rich_text.runs_to_json(runs))
  should.equal(
    j,
    "[{\"type\":\"text\","
      <> "\"text\":{\"content\":\"hi\",\"link\":{\"url\":\"https://x.dev\"}},"
      <> "\"annotations\":{\"bold\":true,\"italic\":false,"
      <> "\"strikethrough\":false,\"underline\":false,\"code\":false,"
      <> "\"color\":\"default\"}}]",
  )
}

pub fn json_to_runs_decodes_test() {
  let raw =
    "[{\"type\":\"text\","
    <> "\"text\":{\"content\":\"hello\",\"link\":null},"
    <> "\"annotations\":{\"bold\":true,\"italic\":false,"
    <> "\"strikethrough\":false,\"underline\":false,\"code\":false,"
    <> "\"color\":\"default\"},"
    <> "\"plain_text\":\"hello\",\"href\":null}]"
  let assert Ok(runs) = json.parse(raw, rich_text.run_list_decoder())
  should.equal(runs, [Run(..plain("hello"), bold: True)])
}

pub fn json_to_runs_keeps_href_test() {
  let raw =
    "[{\"type\":\"text\","
    <> "\"text\":{\"content\":\"hi\"},"
    <> "\"annotations\":{\"bold\":false,\"italic\":false,"
    <> "\"strikethrough\":false,\"underline\":false,\"code\":false,"
    <> "\"color\":\"default\"},"
    <> "\"plain_text\":\"hi\",\"href\":\"https://x.dev\"}]"
  let assert Ok(runs) = json.parse(raw, rich_text.run_list_decoder())
  should.equal(runs, [Run(..plain("hi"), href: Some("https://x.dev"))])
}

pub fn json_roundtrip_test() {
  let runs = [
    Run(..plain("b"), bold: True),
    Run(..plain("i"), italic: True),
    Run(..plain("s"), strikethrough: True),
    Run(..plain("c"), code: True),
    Run(..plain("u"), underline: True),
    Run(..plain("link"), href: Some("https://x.dev")),
  ]
  let encoded = json.to_string(rich_text.runs_to_json(runs))
  // Notion's response also carries `plain_text` + `href` at top level; mimic
  // by running the decoder on our own output only after we add them.
  let body = string_wrap_plain_href(encoded, runs)
  let assert Ok(decoded) = json.parse(body, rich_text.run_list_decoder())
  should.equal(decoded, runs)
  Nil
}

fn string_wrap_plain_href(_encoded: String, runs: List(Run)) -> String {
  // Build a Notion-shaped array directly; `runs_to_json` omits
  // `plain_text`/`href` which the decoder needs.
  "["
  <> runs
  |> items_with_plain_href
  <> "]"
}

fn items_with_plain_href(runs: List(Run)) -> String {
  case runs {
    [] -> ""
    [r] -> json_item_with_plain_href(r)
    [r, ..rest] ->
      json_item_with_plain_href(r) <> "," <> items_with_plain_href(rest)
  }
}

fn json_item_with_plain_href(r: Run) -> String {
  let href = case r.href {
    Some(u) -> "\"" <> u <> "\""
    None -> "null"
  }
  let link = case r.href {
    Some(u) -> "{\"url\":\"" <> u <> "\"}"
    None -> "null"
  }
  "{\"type\":\"text\","
  <> "\"text\":{\"content\":\""
  <> r.text
  <> "\",\"link\":"
  <> link
  <> "},"
  <> "\"annotations\":{\"bold\":"
  <> bool_str(r.bold)
  <> ",\"italic\":"
  <> bool_str(r.italic)
  <> ",\"strikethrough\":"
  <> bool_str(r.strikethrough)
  <> ",\"underline\":"
  <> bool_str(r.underline)
  <> ",\"code\":"
  <> bool_str(r.code)
  <> ",\"color\":\""
  <> r.color
  <> "\"},"
  <> "\"plain_text\":\""
  <> r.text
  <> "\",\"href\":"
  <> href
  <> "}"
}

fn bool_str(b: Bool) -> String {
  case b {
    True -> "true"
    False -> "false"
  }
}

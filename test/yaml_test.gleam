//// Unit tests for the minimal YAML frontmatter parser
//// (`notion_client/yaml`). Parser scope is intentionally narrow —
//// it round-trips the shape emitted by `properties.render_frontmatter`
//// and nothing more.

import gleam/option.{None, Some}
import gleeunit/should
import notion_client/yaml.{YBool, YFloat, YInt, YList, YMap, YNull, YString}

pub fn main() {
  Nil
}

// ─── split_frontmatter ─────────────────────────────────────────────────

pub fn no_frontmatter_test() {
  let #(y, body) = yaml.split_frontmatter("no fence here\n# hi")
  should.equal(y, None)
  should.equal(body, "no fence here\n# hi")
}

pub fn empty_frontmatter_test() {
  let #(y, body) = yaml.split_frontmatter("---\n---\n# body\n")
  should.equal(y, Some(YMap([])))
  should.equal(body, "# body\n")
}

pub fn simple_scalars_test() {
  let src = "---\nid: p1\nurl: \"https://x\"\ntitle: Hello World\n---\n# body"
  let #(y, body) = yaml.split_frontmatter(src)
  should.equal(
    y,
    Some(
      YMap([
        #("id", YString("p1")),
        #("url", YString("https://x")),
        #("title", YString("Hello World")),
      ]),
    ),
  )
  should.equal(body, "# body")
}

pub fn nested_properties_map_test() {
  let src =
    "---\nid: p1\nproperties:\n  Tag: urgent\n  N: 5\n  Done: true\n---\n"
  let #(y, _) = yaml.split_frontmatter(src)
  should.equal(
    y,
    Some(
      YMap([
        #("id", YString("p1")),
        #(
          "properties",
          YMap([
            #("Tag", YString("urgent")),
            #("N", YInt(5)),
            #("Done", YBool(True)),
          ]),
        ),
      ]),
    ),
  )
}

pub fn flow_list_test() {
  let src = "---\nproperties:\n  Tags: [a, b, c]\n---\n"
  let #(y, _) = yaml.split_frontmatter(src)
  should.equal(
    y,
    Some(
      YMap([
        #(
          "properties",
          YMap([
            #("Tags", YList([YString("a"), YString("b"), YString("c")])),
          ]),
        ),
      ]),
    ),
  )
}

pub fn flow_map_test() {
  let src =
    "---\nproperties:\n  Span: { start: 2026-01-01, end: 2026-12-31 }\n---\n"
  let #(y, _) = yaml.split_frontmatter(src)
  should.equal(
    y,
    Some(
      YMap([
        #(
          "properties",
          YMap([
            #(
              "Span",
              YMap([
                #("start", YString("2026-01-01")),
                #("end", YString("2026-12-31")),
              ]),
            ),
          ]),
        ),
      ]),
    ),
  )
}

pub fn quoted_key_with_colon_test() {
  let src = "---\nproperties:\n  \"Scope: phase\": v\n---\n"
  let #(y, _) = yaml.split_frontmatter(src)
  should.equal(
    y,
    Some(
      YMap([
        #("properties", YMap([#("Scope: phase", YString("v"))])),
      ]),
    ),
  )
}

pub fn null_and_bools_test() {
  let src = "---\nproperties:\n  A: null\n  B: true\n  C: false\n---\n"
  let #(y, _) = yaml.split_frontmatter(src)
  should.equal(
    y,
    Some(
      YMap([
        #(
          "properties",
          YMap([
            #("A", YNull),
            #("B", YBool(True)),
            #("C", YBool(False)),
          ]),
        ),
      ]),
    ),
  )
}

pub fn float_scalar_test() {
  let src = "---\nproperties:\n  Price: 3.14\n---\n"
  let #(y, _) = yaml.split_frontmatter(src)
  should.equal(
    y,
    Some(YMap([#("properties", YMap([#("Price", YFloat(3.14))]))])),
  )
}

pub fn quoted_scalar_with_special_chars_test() {
  let src = "---\nproperties:\n  U: \"https://x.com/a?b=1\"\n---\n"
  let #(y, _) = yaml.split_frontmatter(src)
  should.equal(
    y,
    Some(
      YMap([
        #("properties", YMap([#("U", YString("https://x.com/a?b=1"))])),
      ]),
    ),
  )
}

//// Unit tests for phase-24 YAML frontmatter renderer
//// (`notion_client/properties`). Covers:
//// - parent gating (non-DB pages emit no frontmatter)
//// - title + id + url header emission
//// - every property type in spec §8
//// - null-skip vs --full-properties
//// - readonly split
//// - YAML quoting (keys with `:`, reserved words)

import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import notion_client/properties

pub fn main() {
  Nil
}

fn parse(j: String) -> Dynamic {
  let assert Ok(d) = json.parse(j, decode.dynamic)
  d
}

/// Build a minimal DB-parented page JSON with a `Name` title and the
/// given extra property JSON spliced in.
fn db_page(extra_props: String) -> Dynamic {
  let base_title =
    "\"Name\":{\"id\":\"t\",\"type\":\"title\",\"title\":"
    <> "[{\"plain_text\":\"T\"}]}"
  let sep = case extra_props {
    "" -> ""
    _ -> ","
  }
  parse(
    "{\"id\":\"p1\",\"url\":\"u\",\"parent\":"
    <> "{\"type\":\"database_id\",\"database_id\":\"d1\"},"
    <> "\"properties\":{"
    <> base_title
    <> sep
    <> extra_props
    <> "}}",
  )
}

// ─── parent gating ─────────────────────────────────────────────────────

pub fn non_db_parent_returns_none_test() {
  let j =
    "{\"id\":\"p1\",\"url\":\"u\",\"parent\":{\"type\":\"page_id\","
    <> "\"page_id\":\"x\"},\"properties\":{}}"
  should.equal(properties.render_frontmatter(parse(j), False), None)
}

pub fn db_parent_emits_frontmatter_test() {
  let out = properties.render_frontmatter(db_page(""), False)
  should.equal(out, Some("---\nid: p1\nurl: u\ntitle: T\n---\n"))
}

pub fn data_source_parent_emits_frontmatter_test() {
  let j =
    "{\"id\":\"p1\",\"url\":\"u\",\"parent\":{\"type\":\"data_source_id\","
    <> "\"data_source_id\":\"ds1\"},\"properties\":{"
    <> "\"Name\":{\"id\":\"t\",\"type\":\"title\",\"title\":"
    <> "[{\"plain_text\":\"T\"}]}}}"
  let out = properties.render_frontmatter(parse(j), False)
  should.equal(out, Some("---\nid: p1\nurl: u\ntitle: T\n---\n"))
}

// ─── per-type value mapping ────────────────────────────────────────────

pub fn rich_text_prop_test() {
  let p =
    "\"Note\":{\"id\":\"r\",\"type\":\"rich_text\",\"rich_text\":"
    <> "[{\"plain_text\":\"hello \"},{\"plain_text\":\"world\"}]}"
  let out = properties.render_frontmatter(db_page(p), False)
  should.equal(
    out,
    Some(
      "---\nid: p1\nurl: u\ntitle: T\nproperties:\n  Note: hello world\n---\n",
    ),
  )
}

pub fn number_int_prop_test() {
  let p = "\"N\":{\"id\":\"n\",\"type\":\"number\",\"number\":42}"
  let out = properties.render_frontmatter(db_page(p), False)
  should.equal(
    out,
    Some("---\nid: p1\nurl: u\ntitle: T\nproperties:\n  N: 42\n---\n"),
  )
}

pub fn number_null_skipped_without_full_test() {
  let p = "\"N\":{\"id\":\"n\",\"type\":\"number\",\"number\":null}"
  let out = properties.render_frontmatter(db_page(p), False)
  should.equal(out, Some("---\nid: p1\nurl: u\ntitle: T\n---\n"))
}

pub fn number_null_included_with_full_test() {
  let p = "\"N\":{\"id\":\"n\",\"type\":\"number\",\"number\":null}"
  let out = properties.render_frontmatter(db_page(p), True)
  should.equal(
    out,
    Some("---\nid: p1\nurl: u\ntitle: T\nproperties:\n  N: null\n---\n"),
  )
}

pub fn select_prop_test() {
  let p =
    "\"S\":{\"id\":\"s\",\"type\":\"select\",\"select\":"
    <> "{\"id\":\"o\",\"name\":\"urgent\"}}"
  let out = properties.render_frontmatter(db_page(p), False)
  should.equal(
    out,
    Some("---\nid: p1\nurl: u\ntitle: T\nproperties:\n  S: urgent\n---\n"),
  )
}

pub fn status_prop_test() {
  let p =
    "\"St\":{\"id\":\"st\",\"type\":\"status\",\"status\":"
    <> "{\"id\":\"o\",\"name\":\"In progress\"}}"
  let out = properties.render_frontmatter(db_page(p), False)
  should.equal(
    out,
    Some("---\nid: p1\nurl: u\ntitle: T\nproperties:\n  St: In progress\n---\n"),
  )
}

pub fn multi_select_prop_test() {
  let p =
    "\"Tags\":{\"id\":\"m\",\"type\":\"multi_select\",\"multi_select\":"
    <> "[{\"id\":\"a\",\"name\":\"urgent\"},{\"id\":\"b\",\"name\":\"backend\"}]}"
  let out = properties.render_frontmatter(db_page(p), False)
  should.equal(
    out,
    Some(
      "---\nid: p1\nurl: u\ntitle: T\nproperties:\n  Tags: [urgent, backend]\n---\n",
    ),
  )
}

pub fn date_start_only_prop_test() {
  let p =
    "\"Due\":{\"id\":\"d\",\"type\":\"date\",\"date\":"
    <> "{\"start\":\"2026-04-30\",\"end\":null,\"time_zone\":null}}"
  let out = properties.render_frontmatter(db_page(p), False)
  should.equal(
    out,
    Some("---\nid: p1\nurl: u\ntitle: T\nproperties:\n  Due: 2026-04-30\n---\n"),
  )
}

pub fn date_range_prop_test() {
  let p =
    "\"Span\":{\"id\":\"d\",\"type\":\"date\",\"date\":"
    <> "{\"start\":\"2026-04-01\",\"end\":\"2026-04-10\",\"time_zone\":null}}"
  let out = properties.render_frontmatter(db_page(p), False)
  should.equal(
    out,
    Some(
      "---\nid: p1\nurl: u\ntitle: T\nproperties:\n"
      <> "  Span: { start: 2026-04-01, end: 2026-04-10 }\n---\n",
    ),
  )
}

pub fn checkbox_prop_test() {
  let p = "\"Done\":{\"id\":\"c\",\"type\":\"checkbox\",\"checkbox\":true}"
  let out = properties.render_frontmatter(db_page(p), False)
  should.equal(
    out,
    Some("---\nid: p1\nurl: u\ntitle: T\nproperties:\n  Done: true\n---\n"),
  )
}

pub fn url_email_phone_prop_test() {
  let p =
    "\"U\":{\"id\":\"u\",\"type\":\"url\",\"url\":\"https://x.com\"},"
    <> "\"E\":{\"id\":\"e\",\"type\":\"email\",\"email\":\"a@b.co\"},"
    <> "\"P\":{\"id\":\"p\",\"type\":\"phone_number\",\"phone_number\":\"+1\"}"
  let out = properties.render_frontmatter(db_page(p), False)
  should.equal(
    out,
    Some(
      "---\nid: p1\nurl: u\ntitle: T\nproperties:\n"
      <> "  E: \"a@b.co\"\n  P: \"+1\"\n  U: \"https://x.com\"\n---\n",
    ),
  )
}

pub fn people_prop_test() {
  let p =
    "\"Assignee\":{\"id\":\"a\",\"type\":\"people\",\"people\":"
    <> "[{\"object\":\"user\",\"id\":\"u1\"}]}"
  let out = properties.render_frontmatter(db_page(p), False)
  should.equal(
    out,
    Some("---\nid: p1\nurl: u\ntitle: T\nproperties:\n  Assignee: [u1]\n---\n"),
  )
}

pub fn relation_prop_test() {
  let p =
    "\"Rel\":{\"id\":\"r\",\"type\":\"relation\",\"relation\":"
    <> "[{\"id\":\"p42\"}]}"
  let out = properties.render_frontmatter(db_page(p), False)
  should.equal(
    out,
    Some("---\nid: p1\nurl: u\ntitle: T\nproperties:\n  Rel: [p42]\n---\n"),
  )
}

pub fn files_prop_test() {
  let p =
    "\"Files\":{\"id\":\"f\",\"type\":\"files\",\"files\":"
    <> "[{\"name\":\"x\",\"type\":\"external\","
    <> "\"external\":{\"url\":\"https://a/x\"}}]}"
  let out = properties.render_frontmatter(db_page(p), False)
  should.equal(
    out,
    Some(
      "---\nid: p1\nurl: u\ntitle: T\nproperties:\n  Files: [\"https://a/x\"]\n---\n",
    ),
  )
}

// ─── readonly types ────────────────────────────────────────────────────

pub fn readonly_excluded_without_full_test() {
  let p =
    "\"When\":{\"id\":\"w\",\"type\":\"created_time\","
    <> "\"created_time\":\"2026-04-18T01:00:00.000Z\"}"
  let out = properties.render_frontmatter(db_page(p), False)
  should.equal(out, Some("---\nid: p1\nurl: u\ntitle: T\n---\n"))
}

pub fn readonly_included_with_full_test() {
  let p =
    "\"When\":{\"id\":\"w\",\"type\":\"created_time\","
    <> "\"created_time\":\"2026-04-18T01:00:00.000Z\"}"
  let out = properties.render_frontmatter(db_page(p), True)
  should.equal(
    out,
    Some(
      "---\nid: p1\nurl: u\ntitle: T\nproperties_readonly:\n"
      <> "  When: \"2026-04-18T01:00:00.000Z\"\n---\n",
    ),
  )
}

pub fn unique_id_readonly_test() {
  let p =
    "\"Ref\":{\"id\":\"x\",\"type\":\"unique_id\","
    <> "\"unique_id\":{\"prefix\":\"BUG\",\"number\":42}}"
  let out = properties.render_frontmatter(db_page(p), True)
  should.equal(
    out,
    Some(
      "---\nid: p1\nurl: u\ntitle: T\nproperties_readonly:\n"
      <> "  Ref: BUG-42\n---\n",
    ),
  )
}

pub fn formula_string_readonly_test() {
  let p =
    "\"F\":{\"id\":\"f\",\"type\":\"formula\",\"formula\":"
    <> "{\"type\":\"string\",\"string\":\"computed\"}}"
  let out = properties.render_frontmatter(db_page(p), True)
  should.equal(
    out,
    Some(
      "---\nid: p1\nurl: u\ntitle: T\nproperties_readonly:\n  F: computed\n---\n",
    ),
  )
}

// ─── YAML quoting ──────────────────────────────────────────────────────

pub fn key_with_colon_quoted_test() {
  let p =
    "\"Scope: phase\":{\"id\":\"k\",\"type\":\"rich_text\",\"rich_text\":"
    <> "[{\"plain_text\":\"v\"}]}"
  let out = properties.render_frontmatter(db_page(p), False)
  should.equal(
    out,
    Some(
      "---\nid: p1\nurl: u\ntitle: T\nproperties:\n  \"Scope: phase\": v\n---\n",
    ),
  )
}

pub fn reserved_word_value_quoted_test() {
  let p =
    "\"R\":{\"id\":\"r\",\"type\":\"rich_text\",\"rich_text\":"
    <> "[{\"plain_text\":\"null\"}]}"
  let out = properties.render_frontmatter(db_page(p), False)
  should.equal(
    out,
    Some("---\nid: p1\nurl: u\ntitle: T\nproperties:\n  R: \"null\"\n---\n"),
  )
}

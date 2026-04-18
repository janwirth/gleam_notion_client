//// Unit tests for phase-25 `properties.build_patch` — inverse of
//// phase-24 frontmatter emission. Covers every property type, null
//// clears, unknown-name skip, and read-only skip.

import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json
import gleeunit/should
import notion_client/properties
import notion_client/yaml.{
  type Yaml, YBool, YFloat, YInt, YList, YMap, YNull, YString,
}

pub fn main() {
  Nil
}

fn parse(j: String) -> Dynamic {
  let assert Ok(d) = json.parse(j, decode.dynamic)
  d
}

/// Build a minimal page JSON where each entry in `type_list` becomes
/// a property with the given type. Also registers a title property
/// called `Name`.
fn page_with_types(type_list: List(#(String, String))) -> Dynamic {
  let entries =
    ["\"Name\":{\"id\":\"t\",\"type\":\"title\",\"title\":[]}"]
    |> list_extend(type_list, fn(acc, entry) {
      let #(name, kind) = entry
      let line =
        "\""
        <> name
        <> "\":{\"id\":\"x\",\"type\":\""
        <> kind
        <> "\",\""
        <> kind
        <> "\":null}"
      [line, ..acc]
    })
  parse(
    "{\"id\":\"p\",\"url\":\"u\",\"parent\":{\"type\":\"database_id\","
    <> "\"database_id\":\"d\"},\"properties\":{"
    <> join_comma(entries)
    <> "}}",
  )
}

fn list_extend(
  init: List(String),
  xs: List(a),
  f: fn(List(String), a) -> List(String),
) -> List(String) {
  case xs {
    [] -> init
    [h, ..rest] -> list_extend(f(init, h), rest, f)
  }
}

fn join_comma(items: List(String)) -> String {
  case items {
    [] -> ""
    [x] -> x
    [x, ..rest] -> x <> "," <> join_comma(rest)
  }
}

fn ymap_of_properties(entries: List(#(String, Yaml))) -> Yaml {
  YMap([#("properties", YMap(entries))])
}

fn assert_json(y: Yaml, page: Dynamic, expected: String) {
  let #(body, _notes) = properties.build_patch(page, y)
  should.equal(json.to_string(body), expected)
}

// ─── per-type emission ─────────────────────────────────────────────────

pub fn rich_text_string_test() {
  let page = page_with_types([#("Note", "rich_text")])
  let y = ymap_of_properties([#("Note", YString("hi"))])
  assert_json(
    y,
    page,
    "{\"properties\":{\"Note\":{\"rich_text\":[{\"type\":\"text\","
      <> "\"text\":{\"content\":\"hi\"}}]}}}",
  )
}

pub fn rich_text_null_clears_test() {
  let page = page_with_types([#("Note", "rich_text")])
  let y = ymap_of_properties([#("Note", YNull)])
  assert_json(y, page, "{\"properties\":{\"Note\":{\"rich_text\":[]}}}")
}

pub fn number_int_test() {
  let page = page_with_types([#("N", "number")])
  let y = ymap_of_properties([#("N", YInt(42))])
  assert_json(y, page, "{\"properties\":{\"N\":{\"number\":42}}}")
}

pub fn number_float_test() {
  let page = page_with_types([#("N", "number")])
  let y = ymap_of_properties([#("N", YFloat(3.5))])
  assert_json(y, page, "{\"properties\":{\"N\":{\"number\":3.5}}}")
}

pub fn number_null_test() {
  let page = page_with_types([#("N", "number")])
  let y = ymap_of_properties([#("N", YNull)])
  assert_json(y, page, "{\"properties\":{\"N\":{\"number\":null}}}")
}

pub fn select_test() {
  let page = page_with_types([#("S", "select")])
  let y = ymap_of_properties([#("S", YString("urgent"))])
  assert_json(
    y,
    page,
    "{\"properties\":{\"S\":{\"select\":{\"name\":\"urgent\"}}}}",
  )
}

pub fn select_null_test() {
  let page = page_with_types([#("S", "select")])
  let y = ymap_of_properties([#("S", YNull)])
  assert_json(y, page, "{\"properties\":{\"S\":{\"select\":null}}}")
}

pub fn status_test() {
  let page = page_with_types([#("St", "status")])
  let y = ymap_of_properties([#("St", YString("Done"))])
  assert_json(
    y,
    page,
    "{\"properties\":{\"St\":{\"status\":{\"name\":\"Done\"}}}}",
  )
}

pub fn multi_select_test() {
  let page = page_with_types([#("Tags", "multi_select")])
  let y = ymap_of_properties([#("Tags", YList([YString("a"), YString("b")]))])
  assert_json(
    y,
    page,
    "{\"properties\":{\"Tags\":{\"multi_select\":["
      <> "{\"name\":\"a\"},{\"name\":\"b\"}]}}}",
  )
}

pub fn date_string_test() {
  let page = page_with_types([#("D", "date")])
  let y = ymap_of_properties([#("D", YString("2026-04-30"))])
  assert_json(
    y,
    page,
    "{\"properties\":{\"D\":{\"date\":{\"start\":\"2026-04-30\","
      <> "\"end\":null,\"time_zone\":null}}}}",
  )
}

pub fn date_range_test() {
  let page = page_with_types([#("D", "date")])
  let y =
    ymap_of_properties([
      #(
        "D",
        YMap([
          #("start", YString("2026-04-01")),
          #("end", YString("2026-04-10")),
        ]),
      ),
    ])
  assert_json(
    y,
    page,
    "{\"properties\":{\"D\":{\"date\":{\"start\":\"2026-04-01\","
      <> "\"end\":\"2026-04-10\",\"time_zone\":null}}}}",
  )
}

pub fn checkbox_test() {
  let page = page_with_types([#("Done", "checkbox")])
  let y = ymap_of_properties([#("Done", YBool(True))])
  assert_json(y, page, "{\"properties\":{\"Done\":{\"checkbox\":true}}}")
}

pub fn url_test() {
  let page = page_with_types([#("U", "url")])
  let y = ymap_of_properties([#("U", YString("https://x"))])
  assert_json(y, page, "{\"properties\":{\"U\":{\"url\":\"https://x\"}}}")
}

pub fn email_test() {
  let page = page_with_types([#("E", "email")])
  let y = ymap_of_properties([#("E", YString("a@b.co"))])
  assert_json(y, page, "{\"properties\":{\"E\":{\"email\":\"a@b.co\"}}}")
}

pub fn phone_test() {
  let page = page_with_types([#("P", "phone_number")])
  let y = ymap_of_properties([#("P", YString("+1"))])
  assert_json(y, page, "{\"properties\":{\"P\":{\"phone_number\":\"+1\"}}}")
}

pub fn people_test() {
  let page = page_with_types([#("A", "people")])
  let y = ymap_of_properties([#("A", YList([YString("u1")]))])
  assert_json(
    y,
    page,
    "{\"properties\":{\"A\":{\"people\":[{\"id\":\"u1\"}]}}}",
  )
}

pub fn relation_test() {
  let page = page_with_types([#("R", "relation")])
  let y = ymap_of_properties([#("R", YList([YString("p42")]))])
  assert_json(
    y,
    page,
    "{\"properties\":{\"R\":{\"relation\":[{\"id\":\"p42\"}]}}}",
  )
}

pub fn files_test() {
  let page = page_with_types([#("F", "files")])
  let y = ymap_of_properties([#("F", YList([YString("https://a/x")]))])
  assert_json(
    y,
    page,
    "{\"properties\":{\"F\":{\"files\":[{\"name\":\"https://a/x\","
      <> "\"type\":\"external\",\"external\":{\"url\":\"https://a/x\"}}]}}}",
  )
}

// ─── title (top-level) ─────────────────────────────────────────────────

pub fn title_top_level_test() {
  let page = page_with_types([])
  let y = YMap([#("title", YString("New Title"))])
  assert_json(
    y,
    page,
    "{\"properties\":{\"Name\":{\"title\":[{\"type\":\"text\","
      <> "\"text\":{\"content\":\"New Title\"}}]}}}",
  )
}

// ─── read-only / unknown ───────────────────────────────────────────────

pub fn readonly_skip_test() {
  let page = page_with_types([#("W", "created_time")])
  let y = ymap_of_properties([#("W", YString("2026-04-18T00:00:00.000Z"))])
  let #(body, notes) = properties.build_patch(page, y)
  should.equal(json.to_string(body), "{\"properties\":{}}")
  should.equal(notes, ["skip \"W\": read-only created_time"])
}

pub fn unknown_name_skip_test() {
  let page = page_with_types([#("Real", "rich_text")])
  let y = ymap_of_properties([#("Ghost", YString("x"))])
  let #(body, notes) = properties.build_patch(page, y)
  should.equal(json.to_string(body), "{\"properties\":{}}")
  should.equal(notes, ["skip \"Ghost\": not on page"])
}

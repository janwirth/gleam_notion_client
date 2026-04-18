//// YAML frontmatter renderer + inverse patch builder for database-row
//// page properties.
////
//// - `render_frontmatter` takes a decoded page JSON (Dynamic, from
////   `/v1/pages/{id}`) and emits the front-of-markdown YAML block per
////   `specs/v2-markdown-extensions.md` §8. Returns `None` for non-DB
////   pages.
//// - `build_patch` takes the same page JSON plus a parsed YAML tree
////   (`notion_client/yaml`) and emits a PATCH body shaped
////   `{ properties: { … } }` plus a list of notes for read-only /
////   unknown-typed keys that were skipped.

import gleam/dict
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import notion_client/yaml.{type Yaml}

// ─── Value tree ─────────────────────────────────────────────────────────

pub type Value {
  VString(String)
  VInt(Int)
  VFloat(Float)
  VBool(Bool)
  VNull
  VList(List(Value))
  VMap(List(#(String, Value)))
}

type Prop {
  Prop(name: String, value: Value, readonly: Bool)
}

type Page {
  Page(
    id: String,
    url: String,
    title: String,
    is_db_row: Bool,
    props: List(#(String, Dynamic)),
  )
}

// ─── Public entry ───────────────────────────────────────────────────────

/// Render a page's properties as YAML frontmatter (including the leading
/// and trailing `---` fences and a trailing newline). Returns `None` if
/// the page is not a database row.
pub fn render_frontmatter(page: Dynamic, full: Bool) -> Option(String) {
  case decode.run(page, page_decoder()) {
    Error(_) -> None
    Ok(Page(_, _, _, False, _)) -> None
    Ok(Page(id, url, title, True, raw)) -> {
      let props = list.filter_map(raw, decode_prop)
      Some(emit_yaml(id, url, title, props, full))
    }
  }
}

// ─── Page decoder ───────────────────────────────────────────────────────

fn page_decoder() -> decode.Decoder(Page) {
  use id <- decode.field("id", decode.string)
  use url <- decode.field("url", decode.optional(decode.string))
  use parent_type <- decode.subfield(
    ["parent", "type"],
    decode.optional(decode.string),
  )
  use props_dict <- decode.field(
    "properties",
    decode.dict(decode.string, decode.dynamic),
  )
  let is_db = case parent_type {
    Some("database_id") -> True
    Some("data_source_id") -> True
    _ -> False
  }
  let entries =
    dict.to_list(props_dict)
    |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
  let title = extract_title(entries)
  decode.success(Page(id, option.unwrap(url, ""), title, is_db, entries))
}

fn extract_title(entries: List(#(String, Dynamic))) -> String {
  list.fold(entries, "", fn(acc, e) {
    let #(_, raw) = e
    case acc {
      "" ->
        case decode.run(raw, title_value_decoder()) {
          Ok(t) -> t
          Error(_) -> ""
        }
      _ -> acc
    }
  })
}

fn title_value_decoder() -> decode.Decoder(String) {
  use t <- decode.field("type", decode.string)
  case t {
    "title" -> {
      use parts <- decode.field("title", decode.list(plain_text_item_decoder()))
      decode.success(string.join(parts, ""))
    }
    _ -> decode.failure("", "not title")
  }
}

fn plain_text_item_decoder() -> decode.Decoder(String) {
  use t <- decode.field("plain_text", decode.optional(decode.string))
  decode.success(option.unwrap(t, ""))
}

// ─── Per-property decode ────────────────────────────────────────────────

fn decode_prop(entry: #(String, Dynamic)) -> Result(Prop, Nil) {
  let #(name, raw) = entry
  case decode.run(raw, type_tag_decoder()) {
    Error(_) -> Error(Nil)
    Ok(kind) ->
      case kind {
        "title" -> Error(Nil)
        _ ->
          case decode_by_kind(kind, raw) {
            Ok(#(value, readonly)) -> Ok(Prop(name, value, readonly))
            Error(_) -> Ok(Prop(name, VNull, readonly_kind(kind)))
          }
      }
  }
}

fn type_tag_decoder() -> decode.Decoder(String) {
  use t <- decode.field("type", decode.string)
  decode.success(t)
}

fn decode_by_kind(
  kind: String,
  raw: Dynamic,
) -> Result(#(Value, Bool), List(decode.DecodeError)) {
  case kind {
    "rich_text" -> decode.run(raw, rich_text_prop()) |> tag(False)
    "number" -> decode.run(raw, number_prop()) |> tag(False)
    "select" -> decode.run(raw, select_prop("select")) |> tag(False)
    "status" -> decode.run(raw, select_prop("status")) |> tag(False)
    "multi_select" -> decode.run(raw, multi_select_prop()) |> tag(False)
    "date" -> decode.run(raw, date_prop()) |> tag(False)
    "checkbox" -> decode.run(raw, checkbox_prop()) |> tag(False)
    "url" -> decode.run(raw, string_prop("url")) |> tag(False)
    "email" -> decode.run(raw, string_prop("email")) |> tag(False)
    "phone_number" -> decode.run(raw, string_prop("phone_number")) |> tag(False)
    "people" -> decode.run(raw, id_list_prop("people")) |> tag(False)
    "files" -> decode.run(raw, files_prop()) |> tag(False)
    "relation" -> decode.run(raw, id_list_prop("relation")) |> tag(False)
    "unique_id" -> decode.run(raw, unique_id_prop()) |> tag(True)
    "created_time" -> decode.run(raw, string_prop("created_time")) |> tag(True)
    "last_edited_time" ->
      decode.run(raw, string_prop("last_edited_time")) |> tag(True)
    "created_by" -> decode.run(raw, user_id_prop("created_by")) |> tag(True)
    "last_edited_by" ->
      decode.run(raw, user_id_prop("last_edited_by")) |> tag(True)
    "formula" -> decode.run(raw, formula_prop()) |> tag(True)
    "rollup" -> decode.run(raw, rollup_prop()) |> tag(True)
    _ -> Ok(#(VNull, False))
  }
}

fn tag(
  r: Result(Value, List(decode.DecodeError)),
  readonly: Bool,
) -> Result(#(Value, Bool), List(decode.DecodeError)) {
  result.map(r, fn(v) { #(v, readonly) })
}

fn readonly_kind(kind: String) -> Bool {
  case kind {
    "unique_id"
    | "created_time"
    | "last_edited_time"
    | "created_by"
    | "last_edited_by"
    | "formula"
    | "rollup" -> True
    _ -> False
  }
}

fn rich_text_prop() -> decode.Decoder(Value) {
  use parts <- decode.field("rich_text", decode.list(plain_text_item_decoder()))
  decode.success(case string.join(parts, "") {
    "" -> VNull
    s -> VString(s)
  })
}

fn number_prop() -> decode.Decoder(Value) {
  use n <- decode.field(
    "number",
    decode.optional(
      decode.one_of(decode.int |> decode.map(VInt), [
        decode.float |> decode.map(VFloat),
      ]),
    ),
  )
  decode.success(option.unwrap(n, VNull))
}

fn select_prop(key: String) -> decode.Decoder(Value) {
  use name <- decode.subfield(
    [key],
    decode.optional({
      use n <- decode.field("name", decode.string)
      decode.success(n)
    }),
  )
  decode.success(case name {
    Some(s) -> VString(s)
    None -> VNull
  })
}

fn multi_select_prop() -> decode.Decoder(Value) {
  use names <- decode.field(
    "multi_select",
    decode.list({
      use n <- decode.field("name", decode.string)
      decode.success(n)
    }),
  )
  decode.success(VList(list.map(names, VString)))
}

fn date_prop() -> decode.Decoder(Value) {
  use obj <- decode.field("date", decode.optional(date_obj_decoder()))
  decode.success(case obj {
    None -> VNull
    Some(d) -> d
  })
}

fn date_obj_decoder() -> decode.Decoder(Value) {
  use start <- decode.field("start", decode.optional(decode.string))
  use end_ <- decode.field("end", decode.optional(decode.string))
  use tz <- decode.field("time_zone", decode.optional(decode.string))
  let start_s = option.unwrap(start, "")
  decode.success(case end_, tz {
    None, None -> VString(start_s)
    _, _ -> {
      let base = [#("start", VString(start_s))]
      let with_end = case end_ {
        Some(e) -> list.append(base, [#("end", VString(e))])
        None -> base
      }
      let with_tz = case tz {
        Some(z) -> list.append(with_end, [#("time_zone", VString(z))])
        None -> with_end
      }
      VMap(with_tz)
    }
  })
}

fn checkbox_prop() -> decode.Decoder(Value) {
  use b <- decode.field("checkbox", decode.optional(decode.bool))
  decode.success(case b {
    Some(x) -> VBool(x)
    None -> VNull
  })
}

fn string_prop(key: String) -> decode.Decoder(Value) {
  use s <- decode.field(key, decode.optional(decode.string))
  decode.success(case s {
    Some("") -> VNull
    Some(v) -> VString(v)
    None -> VNull
  })
}

fn id_list_prop(key: String) -> decode.Decoder(Value) {
  use items <- decode.field(
    key,
    decode.list({
      use id <- decode.field("id", decode.string)
      decode.success(id)
    }),
  )
  decode.success(VList(list.map(items, VString)))
}

fn files_prop() -> decode.Decoder(Value) {
  use urls <- decode.field("files", decode.list(file_url_decoder()))
  decode.success(VList(list.map(urls, VString)))
}

fn file_url_decoder() -> decode.Decoder(String) {
  decode.one_of(
    {
      use u <- decode.subfield(["external", "url"], decode.string)
      decode.success(u)
    },
    [
      {
        use u <- decode.subfield(["file", "url"], decode.string)
        decode.success(u)
      },
    ],
  )
}

fn user_id_prop(key: String) -> decode.Decoder(Value) {
  use id <- decode.subfield([key, "id"], decode.optional(decode.string))
  decode.success(case id {
    Some(s) -> VString(s)
    None -> VNull
  })
}

fn unique_id_prop() -> decode.Decoder(Value) {
  use prefix <- decode.subfield(
    ["unique_id", "prefix"],
    decode.optional(decode.string),
  )
  use n <- decode.subfield(["unique_id", "number"], decode.optional(decode.int))
  decode.success(case n {
    None -> VNull
    Some(num) -> {
      let body = int.to_string(num)
      let full = case prefix {
        Some(p) if p != "" -> p <> "-" <> body
        _ -> body
      }
      VString(full)
    }
  })
}

fn formula_prop() -> decode.Decoder(Value) {
  use kind <- decode.subfield(["formula", "type"], decode.string)
  case kind {
    "string" -> {
      use s <- decode.subfield(
        ["formula", "string"],
        decode.optional(decode.string),
      )
      decode.success(opt_string(s))
    }
    "number" -> {
      use n <- decode.subfield(
        ["formula", "number"],
        decode.optional(
          decode.one_of(decode.int |> decode.map(VInt), [
            decode.float |> decode.map(VFloat),
          ]),
        ),
      )
      decode.success(option.unwrap(n, VNull))
    }
    "boolean" -> {
      use b <- decode.subfield(
        ["formula", "boolean"],
        decode.optional(decode.bool),
      )
      decode.success(case b {
        Some(x) -> VBool(x)
        None -> VNull
      })
    }
    "date" -> {
      use d <- decode.subfield(
        ["formula", "date"],
        decode.optional(date_obj_decoder()),
      )
      decode.success(option.unwrap(d, VNull))
    }
    _ -> decode.success(VNull)
  }
}

fn rollup_prop() -> decode.Decoder(Value) {
  use kind <- decode.subfield(["rollup", "type"], decode.string)
  case kind {
    "number" -> {
      use n <- decode.subfield(
        ["rollup", "number"],
        decode.optional(
          decode.one_of(decode.int |> decode.map(VInt), [
            decode.float |> decode.map(VFloat),
          ]),
        ),
      )
      decode.success(option.unwrap(n, VNull))
    }
    "array" -> {
      use items <- decode.subfield(
        ["rollup", "array"],
        decode.list(decode.dynamic),
      )
      decode.success(VList(list.map(items, fn(_) { VString("…") })))
    }
    _ -> decode.success(VNull)
  }
}

fn opt_string(s: Option(String)) -> Value {
  case s {
    Some("") -> VNull
    Some(v) -> VString(v)
    None -> VNull
  }
}

// ─── YAML emission ──────────────────────────────────────────────────────

fn emit_yaml(
  id: String,
  url: String,
  title: String,
  props: List(Prop),
  full: Bool,
) -> String {
  let header = [
    "---",
    "id: " <> yaml_scalar_string(id),
    "url: " <> yaml_scalar_string(url),
    "title: " <> yaml_scalar_string(title),
  ]
  let #(editable, readonly) = split_readonly(props)
  let editable_visible = case full {
    True -> editable
    False -> list.filter(editable, fn(p) { p.value != VNull })
  }
  let editable_block = case editable_visible {
    [] -> []
    xs -> ["properties:", ..list.map(xs, prop_line)]
  }
  let readonly_block = case full, readonly {
    True, [_, ..] -> ["properties_readonly:", ..list.map(readonly, prop_line)]
    _, _ -> []
  }
  let lines =
    list.flatten([header, editable_block, readonly_block, ["---", ""]])
  string.join(lines, "\n")
}

fn split_readonly(props: List(Prop)) -> #(List(Prop), List(Prop)) {
  let editable = list.filter(props, fn(p) { !p.readonly })
  let readonly = list.filter(props, fn(p) { p.readonly })
  #(editable, readonly)
}

fn prop_line(p: Prop) -> String {
  "  " <> yaml_key(p.name) <> ": " <> yaml_value(p.value)
}

fn yaml_key(k: String) -> String {
  case needs_quote(k) {
    True -> quote_string(k)
    False -> k
  }
}

fn yaml_value(v: Value) -> String {
  case v {
    VNull -> "null"
    VBool(True) -> "true"
    VBool(False) -> "false"
    VInt(n) -> int.to_string(n)
    VFloat(f) -> float.to_string(f)
    VString(s) -> yaml_scalar_string(s)
    VList(items) -> "[" <> string.join(list.map(items, yaml_value), ", ") <> "]"
    VMap(pairs) ->
      "{ "
      <> string.join(
        list.map(pairs, fn(p) {
          let #(k, v) = p
          yaml_key(k) <> ": " <> yaml_value(v)
        }),
        ", ",
      )
      <> " }"
  }
}

fn yaml_scalar_string(s: String) -> String {
  case needs_quote(s) {
    True -> quote_string(s)
    False -> s
  }
}

fn needs_quote(s: String) -> Bool {
  case s {
    "" -> True
    _ ->
      reserved_word(s)
      || has_special_char(s)
      || string.starts_with(s, "-")
      || string.starts_with(s, "+")
      || string.starts_with(s, "?")
      || string.starts_with(s, " ")
      || string.ends_with(s, " ")
  }
}

fn reserved_word(s: String) -> Bool {
  case s {
    "null" | "Null" | "NULL" -> True
    "true" | "True" | "TRUE" -> True
    "false" | "False" | "FALSE" -> True
    "~" -> True
    _ -> False
  }
}

fn has_special_char(s: String) -> Bool {
  string.contains(s, ":")
  || string.contains(s, "#")
  || string.contains(s, "[")
  || string.contains(s, "]")
  || string.contains(s, "{")
  || string.contains(s, "}")
  || string.contains(s, ",")
  || string.contains(s, "&")
  || string.contains(s, "*")
  || string.contains(s, "!")
  || string.contains(s, "|")
  || string.contains(s, ">")
  || string.contains(s, "'")
  || string.contains(s, "\"")
  || string.contains(s, "%")
  || string.contains(s, "@")
  || string.contains(s, "`")
  || string.contains(s, "\n")
}

fn quote_string(s: String) -> String {
  let escaped =
    s
    |> string.replace("\\", "\\\\")
    |> string.replace("\"", "\\\"")
    |> string.replace("\n", "\\n")
  "\"" <> escaped <> "\""
}

// ─── Reverse: Yaml → Notion property PATCH JSON ────────────────────────

/// Build a `{ properties: { … } }` PATCH body from a parsed YAML tree.
///
/// `page` is the current page JSON (GET /v1/pages/{id}); used to look
/// up each property's `type` so values from YAML can be reshaped
/// correctly. Returns the JSON payload and a list of notes for
/// properties that were silently dropped (read-only type, unknown
/// property name, or unusable value shape).
pub fn build_patch(page: Dynamic, y: Yaml) -> #(Json, List(String)) {
  let type_map = case decode.run(page, property_types_decoder()) {
    Ok(m) -> m
    Error(_) -> dict.new()
  }
  let title_prop_name = find_title_property(type_map)
  let entries_from_props = case yaml.get(y, "properties") {
    Some(pm) -> yaml.map_entries(pm)
    None -> []
  }
  let entries_with_title = case yaml.get(y, "title"), title_prop_name {
    Some(v), Some(name) -> [#(name, v), ..entries_from_props]
    _, _ -> entries_from_props
  }
  let #(json_pairs, notes) =
    list.fold(entries_with_title, #([], []), fn(acc, entry) {
      let #(pairs, log) = acc
      let #(name, value) = entry
      case dict.get(type_map, name) {
        Error(_) -> #(pairs, ["skip \"" <> name <> "\": not on page", ..log])
        Ok(kind) ->
          case build_one(kind, value) {
            Skip(note) -> #(pairs, ["skip \"" <> name <> "\": " <> note, ..log])
            Emit(j) -> #([#(name, j), ..pairs], log)
          }
      }
    })
  let body =
    json.object([
      #("properties", json.object(list.reverse(json_pairs))),
    ])
  #(body, list.reverse(notes))
}

type Emit {
  Emit(json: Json)
  Skip(note: String)
}

fn property_types_decoder() -> decode.Decoder(dict.Dict(String, String)) {
  use props <- decode.field(
    "properties",
    decode.dict(decode.string, type_tag_decoder()),
  )
  decode.success(props)
}

fn find_title_property(m: dict.Dict(String, String)) -> Option(String) {
  dict.to_list(m)
  |> list.find_map(fn(entry) {
    let #(name, kind) = entry
    case kind {
      "title" -> Ok(name)
      _ -> Error(Nil)
    }
  })
  |> option.from_result
}

fn build_one(kind: String, v: Yaml) -> Emit {
  case kind {
    "title" -> emit_rich_wrapper("title", v)
    "rich_text" -> emit_rich_wrapper("rich_text", v)
    "number" -> emit_number(v)
    "checkbox" -> emit_checkbox(v)
    "select" -> emit_named_option("select", v)
    "status" -> emit_named_option("status", v)
    "multi_select" -> emit_multi_select(v)
    "date" -> emit_date(v)
    "url" -> emit_scalar_string("url", v)
    "email" -> emit_scalar_string("email", v)
    "phone_number" -> emit_scalar_string("phone_number", v)
    "people" -> emit_id_list("people", v)
    "relation" -> emit_id_list("relation", v)
    "files" -> emit_files(v)
    "unique_id"
    | "formula"
    | "rollup"
    | "created_time"
    | "last_edited_time"
    | "created_by"
    | "last_edited_by" -> Skip("read-only " <> kind)
    other -> Skip("unsupported type " <> other)
  }
}

fn emit_rich_wrapper(key: String, v: Yaml) -> Emit {
  case v {
    yaml.YNull -> Emit(json.object([#(key, json.array([], fn(x) { x }))]))
    yaml.YString(s) ->
      Emit(json.object([#(key, json.array([s], text_run_json))]))
    _ -> Skip("expected string for " <> key)
  }
}

fn text_run_json(s: String) -> Json {
  json.object([
    #("type", json.string("text")),
    #("text", json.object([#("content", json.string(s))])),
  ])
}

fn emit_number(v: Yaml) -> Emit {
  case v {
    yaml.YNull -> Emit(json.object([#("number", json.null())]))
    yaml.YInt(n) -> Emit(json.object([#("number", json.int(n))]))
    yaml.YFloat(f) -> Emit(json.object([#("number", json.float(f))]))
    _ -> Skip("expected number")
  }
}

fn emit_checkbox(v: Yaml) -> Emit {
  case v {
    yaml.YBool(b) -> Emit(json.object([#("checkbox", json.bool(b))]))
    yaml.YNull -> Emit(json.object([#("checkbox", json.bool(False))]))
    _ -> Skip("expected bool")
  }
}

fn emit_named_option(key: String, v: Yaml) -> Emit {
  case v {
    yaml.YNull -> Emit(json.object([#(key, json.null())]))
    yaml.YString(s) ->
      Emit(
        json.object([
          #(key, json.object([#("name", json.string(s))])),
        ]),
      )
    _ -> Skip("expected string for " <> key)
  }
}

fn emit_multi_select(v: Yaml) -> Emit {
  case v {
    yaml.YNull ->
      Emit(json.object([#("multi_select", json.array([], fn(x) { x }))]))
    yaml.YList(items) -> {
      case list.try_map(items, extract_string) {
        Ok(names) ->
          Emit(
            json.object([
              #(
                "multi_select",
                json.array(names, fn(n) {
                  json.object([#("name", json.string(n))])
                }),
              ),
            ]),
          )
        Error(_) -> Skip("multi_select items must be strings")
      }
    }
    _ -> Skip("expected list for multi_select")
  }
}

fn emit_date(v: Yaml) -> Emit {
  case v {
    yaml.YNull -> Emit(json.object([#("date", json.null())]))
    yaml.YString(s) ->
      Emit(
        json.object([
          #(
            "date",
            json.object([
              #("start", json.string(s)),
              #("end", json.null()),
              #("time_zone", json.null()),
            ]),
          ),
        ]),
      )
    yaml.YMap(_) -> {
      let start = opt_string_field(v, "start")
      let end_ = opt_string_field(v, "end")
      let tz = opt_string_field(v, "time_zone")
      case start {
        None -> Skip("date map missing start")
        Some(s) ->
          Emit(
            json.object([
              #(
                "date",
                json.object([
                  #("start", json.string(s)),
                  #("end", opt_string_json(end_)),
                  #("time_zone", opt_string_json(tz)),
                ]),
              ),
            ]),
          )
      }
    }
    _ -> Skip("expected string or map for date")
  }
}

fn opt_string_field(v: Yaml, key: String) -> Option(String) {
  case yaml.get(v, key) {
    Some(yaml.YString(s)) -> Some(s)
    _ -> None
  }
}

fn opt_string_json(o: Option(String)) -> Json {
  case o {
    Some(s) -> json.string(s)
    None -> json.null()
  }
}

fn emit_scalar_string(key: String, v: Yaml) -> Emit {
  case v {
    yaml.YNull -> Emit(json.object([#(key, json.null())]))
    yaml.YString(s) -> Emit(json.object([#(key, json.string(s))]))
    _ -> Skip("expected string for " <> key)
  }
}

fn emit_id_list(key: String, v: Yaml) -> Emit {
  case v {
    yaml.YNull -> Emit(json.object([#(key, json.array([], fn(x) { x }))]))
    yaml.YList(items) ->
      case list.try_map(items, extract_string) {
        Ok(ids) ->
          Emit(
            json.object([
              #(
                key,
                json.array(ids, fn(id) {
                  json.object([#("id", json.string(id))])
                }),
              ),
            ]),
          )
        Error(_) -> Skip(key <> " items must be strings")
      }
    _ -> Skip("expected list for " <> key)
  }
}

fn emit_files(v: Yaml) -> Emit {
  case v {
    yaml.YNull -> Emit(json.object([#("files", json.array([], fn(x) { x }))]))
    yaml.YList(items) ->
      case list.try_map(items, extract_string) {
        Ok(urls) ->
          Emit(
            json.object([
              #(
                "files",
                json.array(urls, fn(u) {
                  json.object([
                    #("name", json.string(u)),
                    #("type", json.string("external")),
                    #("external", json.object([#("url", json.string(u))])),
                  ])
                }),
              ),
            ]),
          )
        Error(_) -> Skip("files items must be strings")
      }
    _ -> Skip("expected list for files")
  }
}

fn extract_string(v: Yaml) -> Result(String, Nil) {
  case v {
    yaml.YString(s) -> Ok(s)
    _ -> Error(Nil)
  }
}

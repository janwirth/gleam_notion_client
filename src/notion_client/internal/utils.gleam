//// BEAM-compatible reimplementation of `oas/generator/utils`.
//// Upstream is `target = "javascript"`; this mirrors the public API
//// using only Erlang-compatible stdlib + gleam_json.
////
//// Generated `notion_client/operations` and `notion_client/schema`
//// modules import this via post-processing in `scripts/regenerate.sh`.

import gleam/bit_array
import gleam/dict.{type Dict}
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http/request
import gleam/json
import gleam/list
import gleam/option.{None, Some}

pub fn set_method(req, method) {
  request.set_method(req, method)
}

pub fn append_path(req, path) {
  request.set_path(req, req.path <> path)
}

pub fn set_query(req, query) {
  let query =
    list.filter_map(query, fn(q) {
      let #(k, v) = q
      case v {
        Some(v) -> Ok(#(k, v))
        None -> Error(Nil)
      }
    })
  case query {
    [] -> req
    _ -> request.set_query(req, query)
  }
}

pub fn set_body(req, mime, content) {
  req
  |> request.prepend_header("content-type", mime)
  |> request.set_body(content)
}

pub type Any {
  Object(Fields)
  Array(List(Any))
  Boolean(Bool)
  Integer(Int)
  Number(Float)
  String(String)
  Null
}

pub type Fields =
  Dict(String, Any)

pub fn any_decoder() {
  use <- decode.recursive
  decode.one_of(decode.map(fields_decoder(), Object), [
    decode.list(any_decoder()) |> decode.map(Array),
    decode.bool |> decode.map(Boolean),
    decode.int |> decode.map(Integer),
    decode.float |> decode.map(Number),
    decode.map(decode.optional(decode.string), fn(decoded) {
      case decoded {
        Some(str) -> String(str)
        None -> Null
      }
    }),
  ])
}

pub fn fields_decoder() {
  decode.dict(decode.string, any_decoder())
}

pub fn json_to_bits(j) {
  j
  |> json.to_string
  |> bit_array.from_string
}

pub fn any_to_json(any) {
  case any {
    Object(fields) -> fields_to_json(fields)
    Array(items) -> json.array(items, any_to_json)
    Boolean(b) -> json.bool(b)
    Integer(i) -> json.int(i)
    Number(f) -> json.float(f)
    String(s) -> json.string(s)
    Null -> json.null()
  }
}

pub fn fields_to_json(fields) {
  json.dict(fields, fn(x) { x }, any_to_json)
}

pub fn any_to_dynamic(any) {
  case any {
    Object(fields) -> fields_to_dynamic(fields)
    Array(items) -> dynamic.list(list.map(items, any_to_dynamic))
    Boolean(b) -> dynamic.bool(b)
    Integer(i) -> dynamic.int(i)
    Number(f) -> dynamic.float(f)
    String(s) -> dynamic.string(s)
    Null -> dynamic.nil()
  }
}

pub fn fields_to_dynamic(fields) {
  dynamic.properties(
    fields
    |> dict.to_list
    |> list.map(fn(entry) {
      let #(key, value) = entry
      #(dynamic.string(key), any_to_dynamic(value))
    }),
  )
}

pub type Never {
  Never(Never)
}

pub fn dict(d, values) {
  json.dict(d, fn(x) { x }, values)
}

/// Merge a list of JSON objects. Notion's generated code never invokes this
/// (no allOf in the spec). Panics if called.
pub fn merge(_items: List(json.Json)) -> json.Json {
  panic as "utils.merge not supported on BEAM target"
}

pub fn decode_additional(_except, _decoder, next) {
  use additional <- decode.then(decode.success(dict.new()))
  next(additional)
}

pub fn object(entries: List(#(String, json.Json))) {
  list.filter(entries, fn(entry) {
    let #(_, v) = entry
    v != json.null()
  })
  |> json.object
}

//// Minimal YAML frontmatter parser.
////
//// Scope: covers exactly the shape emitted by
//// `notion_client/properties.render_frontmatter` — leading/trailing
//// `---` fences, 2-space indented block maps, double-quoted scalars,
//// flow lists `[a, b]`, and flow maps `{ k: v, k: v }`. Not a general
//// YAML library. Anything outside the emitter's shape returns an error.

import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

pub type Yaml {
  YString(String)
  YNull
  YBool(Bool)
  YInt(Int)
  YFloat(Float)
  YList(List(Yaml))
  YMap(List(#(String, Yaml)))
}

/// Split a markdown document into `(frontmatter_yaml, body)`. Returns
/// `None` for the yaml when the document has no leading `---` fence or
/// the fences can't be matched.
pub fn split_frontmatter(md: String) -> #(Option(Yaml), String) {
  let lines = string.split(md, "\n")
  case lines {
    ["---", ..rest] ->
      case find_close(rest, []) {
        Error(_) -> #(None, md)
        Ok(#(inner, body_lines)) ->
          case parse_map(inner, 0) {
            Ok(#(ymap, _)) -> #(Some(ymap), string.join(body_lines, "\n"))
            Error(_) -> #(None, md)
          }
      }
    _ -> #(None, md)
  }
}

fn find_close(
  lines: List(String),
  acc: List(String),
) -> Result(#(List(String), List(String)), Nil) {
  case lines {
    [] -> Error(Nil)
    ["---", ..rest] -> Ok(#(list.reverse(acc), rest))
    [l, ..rest] -> find_close(rest, [l, ..acc])
  }
}

// ─── block map parser ─────────────────────────────────────────────────

fn parse_map(
  lines: List(String),
  indent: Int,
) -> Result(#(Yaml, List(String)), String) {
  parse_map_loop(lines, indent, [])
}

fn parse_map_loop(
  lines: List(String),
  indent: Int,
  acc: List(#(String, Yaml)),
) -> Result(#(Yaml, List(String)), String) {
  case lines {
    [] -> Ok(#(YMap(list.reverse(acc)), []))
    [line, ..rest] ->
      case string.trim(line) {
        "" -> parse_map_loop(rest, indent, acc)
        _ -> {
          let ind = count_indent(line)
          case ind < indent {
            True -> Ok(#(YMap(list.reverse(acc)), lines))
            False -> {
              let content = string.drop_start(line, indent)
              case parse_key_value(content) {
                Error(e) -> Error(e)
                Ok(#(key, None)) -> {
                  case parse_map(rest, indent + 2) {
                    Error(e) -> Error(e)
                    Ok(#(sub, rest2)) ->
                      parse_map_loop(rest2, indent, [#(key, sub), ..acc])
                  }
                }
                Ok(#(key, Some(v))) ->
                  parse_map_loop(rest, indent, [#(key, v), ..acc])
              }
            }
          }
        }
      }
  }
}

fn count_indent(line: String) -> Int {
  case line {
    " " <> rest -> 1 + count_indent(rest)
    _ -> 0
  }
}

fn parse_key_value(content: String) -> Result(#(String, Option(Yaml)), String) {
  case split_key(content) {
    Error(e) -> Error(e)
    Ok(#(key, rest)) -> {
      let trimmed = string.trim(rest)
      case trimmed {
        "" -> Ok(#(key, None))
        _ ->
          case parse_scalar(trimmed) {
            Ok(v) -> Ok(#(key, Some(v)))
            Error(e) -> Error(e)
          }
      }
    }
  }
}

fn split_key(content: String) -> Result(#(String, String), String) {
  case content {
    "\"" <> _ -> split_quoted_key(content)
    _ ->
      case string.split_once(content, ":") {
        Ok(#(k, v)) -> Ok(#(string.trim(k), v))
        Error(_) -> Error("missing colon in line: " <> content)
      }
  }
}

fn split_quoted_key(content: String) -> Result(#(String, String), String) {
  let assert "\"" <> after = content
  case scan_quoted(after, "") {
    Error(e) -> Error(e)
    Ok(#(key, rest)) ->
      case string.trim_start(rest) {
        ":" <> tail -> Ok(#(key, tail))
        _ -> Error("expected ':' after quoted key")
      }
  }
}

fn scan_quoted(src: String, acc: String) -> Result(#(String, String), String) {
  case string.pop_grapheme(src) {
    Error(_) -> Error("unterminated quoted string")
    Ok(#("\"", rest)) -> Ok(#(acc, rest))
    Ok(#("\\", rest)) ->
      case string.pop_grapheme(rest) {
        Error(_) -> Error("trailing backslash in quoted string")
        Ok(#("n", rest2)) -> scan_quoted(rest2, acc <> "\n")
        Ok(#("t", rest2)) -> scan_quoted(rest2, acc <> "\t")
        Ok(#(c, rest2)) -> scan_quoted(rest2, acc <> c)
      }
    Ok(#(c, rest)) -> scan_quoted(rest, acc <> c)
  }
}

// ─── scalar / flow container parser ───────────────────────────────────

pub fn parse_scalar(raw: String) -> Result(Yaml, String) {
  case string.trim(raw) {
    "" -> Ok(YString(""))
    "null" | "Null" | "NULL" | "~" -> Ok(YNull)
    "true" | "True" | "TRUE" -> Ok(YBool(True))
    "false" | "False" | "FALSE" -> Ok(YBool(False))
    "\"" <> _ as s -> parse_quoted_scalar(s)
    "[" <> _ as s -> parse_flow_list(s)
    "{" <> _ as s -> parse_flow_map(s)
    s ->
      case int.parse(s) {
        Ok(n) -> Ok(YInt(n))
        Error(_) ->
          case float.parse(s) {
            Ok(f) -> Ok(YFloat(f))
            Error(_) -> Ok(YString(s))
          }
      }
  }
}

fn parse_quoted_scalar(s: String) -> Result(Yaml, String) {
  let assert "\"" <> after = s
  case scan_quoted(after, "") {
    Ok(#(v, rest)) ->
      case string.trim(rest) {
        "" -> Ok(YString(v))
        _ -> Error("unexpected data after quoted scalar: " <> rest)
      }
    Error(e) -> Error(e)
  }
}

fn parse_flow_list(s: String) -> Result(Yaml, String) {
  let trimmed = string.trim(s)
  case string.starts_with(trimmed, "["), string.ends_with(trimmed, "]") {
    True, True -> {
      let inner = string.slice(trimmed, 1, string.length(trimmed) - 2)
      case string.trim(inner) {
        "" -> Ok(YList([]))
        _ -> {
          let parts = split_flow(inner)
          case list.try_map(parts, parse_scalar) {
            Ok(items) -> Ok(YList(items))
            Error(e) -> Error(e)
          }
        }
      }
    }
    _, _ -> Error("malformed flow list: " <> s)
  }
}

fn parse_flow_map(s: String) -> Result(Yaml, String) {
  let trimmed = string.trim(s)
  case string.starts_with(trimmed, "{"), string.ends_with(trimmed, "}") {
    True, True -> {
      let inner = string.slice(trimmed, 1, string.length(trimmed) - 2)
      case string.trim(inner) {
        "" -> Ok(YMap([]))
        _ -> {
          let parts = split_flow(inner)
          case list.try_map(parts, parse_flow_pair) {
            Ok(entries) -> Ok(YMap(entries))
            Error(e) -> Error(e)
          }
        }
      }
    }
    _, _ -> Error("malformed flow map: " <> s)
  }
}

fn parse_flow_pair(raw: String) -> Result(#(String, Yaml), String) {
  case parse_key_value(string.trim(raw)) {
    Ok(#(k, Some(v))) -> Ok(#(k, v))
    Ok(#(k, None)) -> Ok(#(k, YNull))
    Error(e) -> Error(e)
  }
}

/// Split a flow-container inner body by top-level commas, respecting
/// nested `[]`/`{}` and double-quoted strings.
fn split_flow(src: String) -> List(String) {
  split_flow_loop(src, "", [], 0, False)
}

fn split_flow_loop(
  src: String,
  cur: String,
  acc: List(String),
  depth: Int,
  in_quote: Bool,
) -> List(String) {
  case string.pop_grapheme(src) {
    Error(_) ->
      case string.trim(cur) {
        "" -> list.reverse(acc)
        _ -> list.reverse([cur, ..acc])
      }
    Ok(#(c, rest)) ->
      case in_quote, c {
        True, "\\" ->
          case string.pop_grapheme(rest) {
            Ok(#(nxt, rest2)) ->
              split_flow_loop(rest2, cur <> "\\" <> nxt, acc, depth, True)
            Error(_) -> list.reverse([cur <> "\\", ..acc])
          }
        True, "\"" -> split_flow_loop(rest, cur <> "\"", acc, depth, False)
        True, _ -> split_flow_loop(rest, cur <> c, acc, depth, True)
        False, "\"" -> split_flow_loop(rest, cur <> "\"", acc, depth, True)
        False, "[" | False, "{" ->
          split_flow_loop(rest, cur <> c, acc, depth + 1, False)
        False, "]" | False, "}" ->
          split_flow_loop(rest, cur <> c, acc, depth - 1, False)
        False, "," ->
          case depth {
            0 -> split_flow_loop(rest, "", [cur, ..acc], 0, False)
            _ -> split_flow_loop(rest, cur <> ",", acc, depth, False)
          }
        False, _ -> split_flow_loop(rest, cur <> c, acc, depth, False)
      }
  }
}

// ─── lookup helpers ───────────────────────────────────────────────────

/// Look up a top-level key on a `YMap`. Returns `None` if the key is
/// absent or the argument is not a map.
pub fn get(y: Yaml, key: String) -> Option(Yaml) {
  case y {
    YMap(entries) ->
      list.find_map(entries, fn(e) {
        let #(k, v) = e
        case k == key {
          True -> Ok(v)
          False -> Error(Nil)
        }
      })
      |> option.from_result
    _ -> None
  }
}

pub fn map_entries(y: Yaml) -> List(#(String, Yaml)) {
  case y {
    YMap(entries) -> entries
    _ -> []
  }
}

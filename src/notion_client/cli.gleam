//// CLI entry point.
////
//// ```text
//// notion_client read <page_id> [--write-file]
//// notion_client append <page_id> <markdown>
//// notion_client append <page_id> --from-file <path>
//// ```
////
//// Env: `NOTION_TOKEN` (required), `NOTION_API_VERSION` (optional).

import argv
import gleam/dict
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import envoy
import gleam/http
import gleam/http/request
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import notion_client.{type Client}
import notion_client/error.{type NotionError}
import notion_client/markdown.{type Block}
import simplifile

pub fn main() -> Nil {
  case argv.load().arguments {
    ["read", page_id, ..rest] -> cmd_read(page_id, rest)
    ["append", page_id, "--from-file", path] -> cmd_append_file(page_id, path)
    ["append", page_id, body] -> cmd_append_text(page_id, body)
    _ -> print_help()
  }
}

fn print_help() -> Nil {
  io.println(
    "Usage:
  notion_client read <page_id> [--write-file]
  notion_client append <page_id> <markdown>
  notion_client append <page_id> --from-file <path>

Env: NOTION_TOKEN required.",
  )
}

// ─── read ───────────────────────────────────────────────────────────────

fn cmd_read(page_id: String, flags: List(String)) -> Nil {
  let write_file = list.contains(flags, "--write-file")
  case with_client(fn(c) { do_read(c, page_id) }) {
    Error(msg) -> die(msg)
    Ok(#(title, body)) ->
      case write_file {
        False -> io.println(body)
        True -> {
          let path = slugify(title) <> ".md"
          case simplifile.write(path, body) {
            Ok(_) -> io.println("wrote " <> path)
            Error(e) -> die("write failed: " <> simplifile.describe_error(e))
          }
        }
      }
  }
}

fn do_read(
  client: Client,
  page_id: String,
) -> Result(#(String, String), String) {
  use title <- result.try(fetch_title(client, page_id))
  use blocks <- result.try(fetch_block_tree(client, page_id))
  let md = "# " <> title <> "\n\n" <> markdown.to_markdown(blocks)
  Ok(#(title, md))
}

fn fetch_title(client: Client, page_id: String) -> Result(String, String) {
  let req =
    notion_client.base_request(client)
    |> request.set_method(http.Get)
    |> request.set_path("/v1/pages/" <> page_id)
  use body <- result.try(send(client, req))
  Ok(
    decode.run(body, title_decoder())
    |> result.unwrap("untitled"),
  )
}

fn title_decoder() -> decode.Decoder(String) {
  use props <- decode.field(
    "properties",
    decode.dict(decode.string, title_property_decoder()),
  )
  let text =
    dict.values(props)
    |> list.find_map(fn(v) {
      case v {
        Some(s) -> Ok(s)
        None -> Error(Nil)
      }
    })
    |> result.unwrap("untitled")
  decode.success(text)
}

fn title_property_decoder() -> decode.Decoder(option.Option(String)) {
  use type_ <- decode.field("type", decode.string)
  case type_ {
    "title" -> {
      use rt <- decode.field("title", decode.list(plain_text_decoder()))
      decode.success(Some(string.join(rt, "")))
    }
    _ -> decode.success(None)
  }
}

fn plain_text_decoder() -> decode.Decoder(String) {
  use t <- decode.field("plain_text", decode.optional(decode.string))
  decode.success(option.unwrap(t, ""))
}

fn fetch_block_tree(
  client: Client,
  block_id: String,
) -> Result(List(Block), String) {
  use entries <- result.try(fetch_children_page(client, block_id))
  list.try_map(entries, fn(entry) {
    let #(b, id, has_children) = entry
    case has_children {
      False -> Ok(b)
      True -> {
        use kids <- result.try(fetch_block_tree(client, id))
        Ok(markdown.with_children(b, kids))
      }
    }
  })
}

fn fetch_children_page(
  client: Client,
  block_id: String,
) -> Result(List(#(Block, String, Bool)), String) {
  let req =
    notion_client.base_request(client)
    |> request.set_method(http.Get)
    |> request.set_path("/v1/blocks/" <> block_id <> "/children")
  use body <- result.try(send(client, req))
  decode.run(body, children_decoder())
  |> result.map_error(fn(_) { "decode children failed" })
}

fn children_decoder() -> decode.Decoder(List(#(Block, String, Bool))) {
  use results <- decode.field("results", decode.list(block_entry_decoder()))
  decode.success(results)
}

fn block_entry_decoder() -> decode.Decoder(#(Block, String, Bool)) {
  use b <- decode.then(markdown.block_decoder())
  use id <- decode.field("id", decode.string)
  use has_children <- decode.field(
    "has_children",
    decode.optional(decode.bool),
  )
  decode.success(#(b, id, option.unwrap(has_children, False)))
}

// ─── append ─────────────────────────────────────────────────────────────

fn cmd_append_text(page_id: String, md: String) -> Nil {
  case with_client(fn(c) { do_append(c, page_id, md) }) {
    Ok(_) -> io.println("appended")
    Error(msg) -> die(msg)
  }
}

fn cmd_append_file(page_id: String, path: String) -> Nil {
  case simplifile.read(path) {
    Error(e) -> die("read " <> path <> ": " <> simplifile.describe_error(e))
    Ok(md) -> cmd_append_text(page_id, md)
  }
}

fn do_append(
  client: Client,
  page_id: String,
  md: String,
) -> Result(Dynamic, String) {
  let body = markdown.from_markdown(md)
  let req =
    notion_client.base_request(client)
    |> request.set_method(http.Patch)
    |> request.set_path("/v1/blocks/" <> page_id <> "/children")
    |> request.set_body(<<json.to_string(body):utf8>>)
  send(client, req)
}

// ─── transport ─────────────────────────────────────────────────────────

fn send(
  client: Client,
  req: request.Request(BitArray),
) -> Result(Dynamic, String) {
  case notion_client.request(client, req) {
    Error(e) -> Error(error_to_string(e))
    Ok(resp) ->
      case json.parse_bits(resp.body, decode.dynamic) {
        Ok(d) -> Ok(d)
        Error(_) -> Error("invalid json response")
      }
  }
}

fn error_to_string(e: NotionError) -> String {
  case e {
    error.ApiResponseError(code: _, status: s, message: m) ->
      "api " <> string.inspect(s) <> ": " <> m
    error.ClientError(code: _) -> "client error"
  }
}

// ─── env + util ────────────────────────────────────────────────────────

fn with_client(run: fn(Client) -> Result(a, String)) -> Result(a, String) {
  use token <- result.try(
    envoy.get("NOTION_TOKEN")
    |> result.replace_error("NOTION_TOKEN not set"),
  )
  let base = notion_client.new(token)
  let client = case envoy.get("NOTION_API_VERSION") {
    Ok(v) -> notion_client.Client(..base, notion_version: v)
    Error(_) -> base
  }
  run(client)
}

fn die(msg: String) -> Nil {
  io.println_error("error: " <> msg)
  halt(1)
}

@external(erlang, "erlang", "halt")
fn halt(code: Int) -> Nil

fn slugify(s: String) -> String {
  s
  |> string.lowercase
  |> string.to_graphemes
  |> list.map(fn(c) {
    case is_safe_char(c) {
      True -> c
      False -> "-"
    }
  })
  |> string.join("")
  |> collapse_dashes
  |> string.trim
}

fn is_safe_char(c: String) -> Bool {
  case c {
    "a" | "b" | "c" | "d" | "e" | "f" | "g" | "h" | "i" | "j" -> True
    "k" | "l" | "m" | "n" | "o" | "p" | "q" | "r" | "s" | "t" -> True
    "u" | "v" | "w" | "x" | "y" | "z" -> True
    "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> True
    "-" -> True
    _ -> False
  }
}

fn collapse_dashes(s: String) -> String {
  case string.contains(s, "--") {
    True -> collapse_dashes(string.replace(s, "--", "-"))
    False -> s
  }
}

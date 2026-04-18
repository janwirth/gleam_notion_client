//// CLI entry point.
////
//// ```text
//// notion_client read <page_id> [--write-file] [--max-depth N] [--inline-synced] [--full-properties]
//// notion_client append <page_id> <markdown>
//// notion_client append <page_id> --from-file <path>
//// ```
////
//// Env: `NOTION_TOKEN` (required), `NOTION_API_VERSION` (optional).

import argv
import envoy
import gleam/dict
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set.{type Set}
import gleam/string
import notion_client.{type Client}
import notion_client/error.{type NotionError}
import notion_client/markdown.{type Block}
import notion_client/properties
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
  notion_client read <page_id> [--write-file] [--max-depth N] [--inline-synced] [--full-properties]
  notion_client append <page_id> <markdown>
  notion_client append <page_id> --from-file <path>

Env: NOTION_TOKEN required.",
  )
}

// ─── read ───────────────────────────────────────────────────────────────

fn cmd_read(page_id: String, flags: List(String)) -> Nil {
  let write_file = list.contains(flags, "--write-file")
  let max_depth = parse_max_depth(flags, 3)
  let inline_synced = list.contains(flags, "--inline-synced")
  let full_props = list.contains(flags, "--full-properties")
  case
    with_client(fn(c) {
      do_read(c, page_id, max_depth, inline_synced, full_props)
    })
  {
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

fn parse_max_depth(flags: List(String), default: Int) -> Int {
  case flags {
    [] -> default
    ["--max-depth", n, ..] ->
      case int.parse(n) {
        Ok(v) if v >= 0 -> v
        _ -> default
      }
    [_, ..rest] -> parse_max_depth(rest, default)
  }
}

fn do_read(
  client: Client,
  page_id: String,
  max_depth: Int,
  inline_synced: Bool,
  full_props: Bool,
) -> Result(#(String, String), String) {
  use page <- result.try(fetch_page(client, page_id))
  let title =
    decode.run(page, title_decoder())
    |> result.unwrap("untitled")
  let frontmatter = case properties.render_frontmatter(page, full_props) {
    Some(fm) -> fm <> "\n"
    None -> ""
  }
  use blocks <- result.try(fetch_block_tree(
    client,
    page_id,
    0,
    max_depth,
    inline_synced,
    set.new(),
  ))
  let md =
    frontmatter <> "# " <> title <> "\n\n" <> markdown.to_markdown(blocks)
  Ok(#(title, md))
}

fn fetch_page(client: Client, page_id: String) -> Result(Dynamic, String) {
  let req =
    notion_client.base_request(client)
    |> request.set_method(http.Get)
    |> request.set_path("/v1/pages/" <> page_id)
  send(client, req)
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
  depth: Int,
  max_depth: Int,
  inline_synced: Bool,
  visited: Set(String),
) -> Result(List(Block), String) {
  use entries <- result.try(fetch_children_page(client, block_id))
  list.try_map(entries, fn(entry) {
    let #(b, id, has_children) = entry
    case b {
      markdown.ChildPage(cp_id, title, _, _, _) ->
        resolve_child_page(
          client,
          cp_id,
          title,
          depth,
          max_depth,
          inline_synced,
          visited,
        )
      markdown.SyncedBlock(sb_id, src, _, _) ->
        resolve_synced_block(
          client,
          sb_id,
          src,
          id,
          has_children,
          depth,
          max_depth,
          inline_synced,
          visited,
        )
      _ ->
        case has_children {
          False -> Ok(b)
          True -> {
            use kids <- result.try(fetch_block_tree(
              client,
              id,
              depth,
              max_depth,
              inline_synced,
              visited,
            ))
            Ok(markdown.with_children(b, kids))
          }
        }
    }
  })
}

fn resolve_child_page(
  client: Client,
  cp_id: String,
  title: String,
  depth: Int,
  max_depth: Int,
  inline_synced: Bool,
  visited: Set(String),
) -> Result(Block, String) {
  case set.contains(visited, cp_id) {
    True ->
      Ok(markdown.ChildPage(cp_id, title, depth, [], markdown.CycleDetected))
    False ->
      case depth >= max_depth {
        True ->
          Ok(markdown.ChildPage(
            cp_id,
            title,
            depth,
            [],
            markdown.DepthLimitReached,
          ))
        False -> {
          use kids <- result.try(fetch_block_tree(
            client,
            cp_id,
            depth + 1,
            max_depth,
            inline_synced,
            set.insert(visited, cp_id),
          ))
          Ok(markdown.ChildPage(cp_id, title, depth + 1, kids, markdown.Inlined))
        }
      }
  }
}

fn resolve_synced_block(
  client: Client,
  sb_id: String,
  src: option.Option(String),
  entry_id: String,
  has_children: Bool,
  depth: Int,
  max_depth: Int,
  inline_synced: Bool,
  visited: Set(String),
) -> Result(Block, String) {
  case src {
    None -> {
      case has_children {
        False ->
          Ok(markdown.SyncedBlock(sb_id, None, [], markdown.SyncedOriginal))
        True -> {
          use kids <- result.try(fetch_block_tree(
            client,
            entry_id,
            depth,
            max_depth,
            inline_synced,
            visited,
          ))
          Ok(markdown.SyncedBlock(sb_id, None, kids, markdown.SyncedOriginal))
        }
      }
    }
    Some(src_id) ->
      case inline_synced {
        False ->
          Ok(markdown.SyncedBlock(
            sb_id,
            Some(src_id),
            [],
            markdown.SyncedReference,
          ))
        True ->
          case set.contains(visited, src_id) {
            True ->
              Ok(markdown.SyncedBlock(
                sb_id,
                Some(src_id),
                [],
                markdown.SyncedCycle,
              ))
            False -> {
              use kids <- result.try(fetch_block_tree(
                client,
                src_id,
                depth,
                max_depth,
                inline_synced,
                set.insert(visited, src_id),
              ))
              Ok(markdown.SyncedBlock(
                sb_id,
                Some(src_id),
                kids,
                markdown.SyncedInlined,
              ))
            }
          }
      }
  }
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
  use has_children <- decode.field("has_children", decode.optional(decode.bool))
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

fn do_append(client: Client, page_id: String, md: String) -> Result(Nil, String) {
  apply_segments(client, page_id, markdown.segment_markdown(md))
}

fn apply_segments(
  client: Client,
  parent_id: String,
  segments: List(markdown.WriteSegment),
) -> Result(Nil, String) {
  case segments {
    [] -> Ok(Nil)
    [seg, ..rest] -> {
      use _ <- result.try(apply_segment(client, parent_id, seg))
      apply_segments(client, parent_id, rest)
    }
  }
}

fn apply_segment(
  client: Client,
  parent_id: String,
  seg: markdown.WriteSegment,
) -> Result(Nil, String) {
  case seg {
    markdown.PlainMarkdown(md) -> append_plain(client, parent_id, md)
    markdown.AppendSubpage(id, body) ->
      apply_segments(client, id, markdown.segment_markdown(body))
    markdown.CreateSubpage(title, body) -> {
      use new_id <- result.try(create_subpage(client, parent_id, title))
      apply_segments(client, new_id, markdown.segment_markdown(body))
    }
  }
}

fn append_plain(
  client: Client,
  parent_id: String,
  md: String,
) -> Result(Nil, String) {
  let body = markdown.from_markdown(md)
  let req =
    notion_client.base_request(client)
    |> request.set_method(http.Patch)
    |> request.set_path("/v1/blocks/" <> parent_id <> "/children")
    |> request.set_body(<<json.to_string(body):utf8>>)
  use _ <- result.try(send(client, req))
  Ok(Nil)
}

fn create_subpage(
  client: Client,
  parent_id: String,
  title: String,
) -> Result(String, String) {
  let body =
    json.object([
      #("parent", json.object([#("page_id", json.string(parent_id))])),
      #("properties", json.object([#("title", title_property_json(title))])),
    ])
  let req =
    notion_client.base_request(client)
    |> request.set_method(http.Post)
    |> request.set_path("/v1/pages")
    |> request.set_body(<<json.to_string(body):utf8>>)
  use resp <- result.try(send(client, req))
  case decode.run(resp, id_decoder()) {
    Ok(id) -> Ok(id)
    Error(_) -> Error("create subpage: missing id")
  }
}

fn title_property_json(title: String) -> json.Json {
  json.array([title], fn(t) {
    json.object([
      #("type", json.string("text")),
      #("text", json.object([#("content", json.string(t))])),
    ])
  })
}

fn id_decoder() -> decode.Decoder(String) {
  use id <- decode.field("id", decode.string)
  decode.success(id)
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

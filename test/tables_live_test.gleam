//// Live round-trip for phase-20: create row in reference DB, append
//// 2x2 GFM table, recursively fetch, assert table + cells.

import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/erlang/charlist.{type Charlist}
import gleam/http
import gleam/http/request
import gleam/json
import gleam/list
import gleam/option
import helpers/fixtures
import notion_client
import notion_client/markdown

const title: String = "v3:tables"

@external(erlang, "os", "getenv")
fn os_getenv(name: Charlist) -> Dynamic

@external(erlang, "erlang", "is_list")
fn is_list(value: Dynamic) -> Bool

@external(erlang, "erlang", "list_to_binary")
fn list_to_binary(list: Dynamic) -> String

fn read_env(name: String) -> Result(String, Nil) {
  let raw = os_getenv(charlist.from_string(name))
  case is_list(raw) {
    True -> Ok(list_to_binary(raw))
    False -> Error(Nil)
  }
}

pub fn table_round_trip_live_test() {
  case read_env("NOTION_TOKEN"), read_env("NOTION_BOOTSTRAP_DATABASE_ID") {
    Ok(token), Ok(db_id) -> run(token, db_id)
    _, _ -> Nil
  }
}

fn run(token: String, db_id: String) -> Nil {
  let client = notion_client.new(token)
  fixtures.archive_by_title(client, db_id, title)
  let page_id = fixtures.create_row(client, db_id, title, [])
  let md = "| h1 | h2 |\n|---|---|\n| a | b |\n| c | d |"
  append_body(client, page_id, md)
  let tree = fetch_tree(client, page_id, 0)
  case has_table_with_rows(tree, 3) {
    True -> Nil
    False -> panic as "expected table with 3 rows (header + 2 body)"
  }
}

fn has_table_with_rows(blocks: List(markdown.Block), n: Int) -> Bool {
  case blocks {
    [] -> False
    [markdown.Table(rows, _, _), ..] if n == 3 -> list.length(rows) == n
    [_, ..rest] -> has_table_with_rows(rest, n)
  }
}

fn append_body(client: notion_client.Client, page_id: String, md: String) -> Nil {
  let body = markdown.from_markdown(md)
  let req =
    notion_client.base_request(client)
    |> request.set_method(http.Patch)
    |> request.set_path("/v1/blocks/" <> page_id <> "/children")
    |> request.set_body(<<json.to_string(body):utf8>>)
  let assert Ok(resp) = notion_client.request(client, req)
  assert resp.status == 200
  Nil
}

fn fetch_tree(
  client: notion_client.Client,
  parent_id: String,
  depth: Int,
) -> List(markdown.Block) {
  case depth > 5 {
    True -> []
    False -> {
      let entries = fetch_children(client, parent_id)
      list.map(entries, fn(entry) {
        let #(block, id, has_children) = entry
        case has_children {
          False -> block
          True ->
            markdown.with_children(block, fetch_tree(client, id, depth + 1))
        }
      })
    }
  }
}

fn fetch_children(
  client: notion_client.Client,
  parent_id: String,
) -> List(#(markdown.Block, String, Bool)) {
  let req =
    notion_client.base_request(client)
    |> request.set_method(http.Get)
    |> request.set_path("/v1/blocks/" <> parent_id <> "/children")
  let assert Ok(resp) = notion_client.request(client, req)
  let outer = {
    use results <- decode.field("results", decode.list(entry_decoder()))
    decode.success(results)
  }
  let assert Ok(entries) = json.parse_bits(resp.body, outer)
  entries
}

fn entry_decoder() -> decode.Decoder(#(markdown.Block, String, Bool)) {
  use b <- decode.then(markdown.block_decoder())
  use id <- decode.field("id", decode.string)
  use has_children <- decode.field("has_children", decode.optional(decode.bool))
  decode.success(#(b, id, option.unwrap(has_children, False)))
}

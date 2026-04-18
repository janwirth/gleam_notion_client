//// Live round-trip for phase-19: create row in reference DB, append
//// iframe, re-read, assert URL preserved.

import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/erlang/charlist.{type Charlist}
import gleam/http
import gleam/http/request
import gleam/json
import helpers/fixtures
import notion_client
import notion_client/markdown

const title: String = "v3:iframes"

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

pub fn iframe_round_trip_live_test() {
  case read_env("NOTION_TOKEN"), read_env("NOTION_BOOTSTRAP_DATABASE_ID") {
    Ok(token), Ok(db_id) -> run(token, db_id)
    _, _ -> Nil
  }
}

fn run(token: String, db_id: String) -> Nil {
  let client = notion_client.new(token)
  fixtures.archive_by_title(client, db_id, title)
  let page_id = fixtures.create_row(client, db_id, title, [])
  let url = "https://www.example.com/widget"
  let md = "<iframe src=\"" <> url <> "\"></iframe>"
  append_body(client, page_id, md)
  let blocks = fetch_children(client, page_id)
  case has_embed(blocks, url) {
    True -> Nil
    False -> panic as "expected embed block with URL to survive"
  }
}

fn has_embed(blocks: List(markdown.Block), url: String) -> Bool {
  case blocks {
    [] -> False
    [markdown.Embed(u, _), ..] if u == url -> True
    [_, ..rest] -> has_embed(rest, url)
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

fn fetch_children(
  client: notion_client.Client,
  page_id: String,
) -> List(markdown.Block) {
  let req =
    notion_client.base_request(client)
    |> request.set_method(http.Get)
    |> request.set_path("/v1/blocks/" <> page_id <> "/children")
  let assert Ok(resp) = notion_client.request(client, req)
  assert resp.status == 200
  let outer = {
    use results <- decode.field(
      "results",
      decode.list(markdown.block_decoder()),
    )
    decode.success(results)
  }
  let assert Ok(blocks) = json.parse_bits(resp.body, outer)
  blocks
}

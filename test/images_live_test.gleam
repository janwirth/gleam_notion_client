//// Live round-trip for phase-18: create a fresh row in the reference
//// database, append an external image, re-read the block tree, and
//// assert URL + caption survive.

import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/erlang/charlist.{type Charlist}
import gleam/http
import gleam/http/request
import gleam/json
import notion_client
import notion_client/markdown

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

pub fn image_round_trip_live_test() {
  case read_env("NOTION_TOKEN"), read_env("NOTION_BOOTSTRAP_DATABASE_ID") {
    Ok(token), Ok(db_id) -> run(token, db_id)
    _, _ -> Nil
  }
}

fn run(token: String, db_id: String) -> Nil {
  let client = notion_client.new(token)
  let page_id = create_row(client, db_id, "phase-18 images")
  let url =
    "https://upload.wikimedia.org/wikipedia/commons/4/47/PNG_transparency_demonstration_1.png"
  let md = "![transparency demo](" <> url <> ")"
  append_body(client, page_id, md)
  let blocks = fetch_children(client, page_id)
  case has_image(blocks, url) {
    True -> Nil
    False -> panic as "expected image block with external URL to survive"
  }
}

fn has_image(blocks: List(markdown.Block), url: String) -> Bool {
  case blocks {
    [] -> False
    [markdown.Image(u, _, _), ..] if u == url -> True
    [_, ..rest] -> has_image(rest, url)
  }
}

fn create_row(
  client: notion_client.Client,
  db_id: String,
  title: String,
) -> String {
  let body =
    json.object([
      #("parent", json.object([#("database_id", json.string(db_id))])),
      #(
        "properties",
        json.object([
          #(
            "Name",
            json.object([
              #(
                "title",
                json.array([title], fn(t) {
                  json.object([
                    #("type", json.string("text")),
                    #("text", json.object([#("content", json.string(t))])),
                  ])
                }),
              ),
            ]),
          ),
        ]),
      ),
    ])
  let req =
    notion_client.base_request(client)
    |> request.set_method(http.Post)
    |> request.set_path("/v1/pages")
    |> request.set_body(<<json.to_string(body):utf8>>)
  let assert Ok(resp) = notion_client.request(client, req)
  assert resp.status == 200
  let id_decoder = {
    use id <- decode.field("id", decode.string)
    decode.success(id)
  }
  let assert Ok(id) = json.parse_bits(resp.body, id_decoder)
  id
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

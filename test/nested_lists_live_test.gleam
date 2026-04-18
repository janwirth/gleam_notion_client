//// Live round-trip for phase-17: create a fresh row in the reference
//// database, append a 3-deep nested bullet list, refetch the block tree
//// recursively, and assert parent/child nesting survived.

import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/erlang/charlist.{type Charlist}
import gleam/http
import gleam/http/request
import gleam/json
import gleam/list
import gleam/option
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

pub fn nested_list_round_trip_live_test() {
  case read_env("NOTION_TOKEN"), read_env("NOTION_BOOTSTRAP_DATABASE_ID") {
    Ok(token), Ok(db_id) -> run(token, db_id)
    _, _ -> Nil
  }
}

fn run(token: String, db_id: String) -> Nil {
  let client = notion_client.new(token)
  let page_id = create_row(client, db_id, "phase-17 nesting")
  append_body(
    client,
    page_id,
    "- level-0-a\n  - level-1-a\n    - level-2-a\n  - level-1-b\n- level-0-b",
  )
  let tree = fetch_tree(client, page_id, 0)
  // Expect: two top-level bullets; first has two children; first child has
  // one grandchild.
  let first = case tree {
    [markdown.BulletedListItem(_, children), _, ..] -> children
    _ -> panic as "expected 2+ top-level bullets"
  }
  case first {
    [markdown.BulletedListItem(_, grand), markdown.BulletedListItem(_, _), ..] ->
      case grand {
        [markdown.BulletedListItem(_, _), ..] -> Nil
        _ -> panic as "missing level-2 grandchild"
      }
    _ -> panic as "expected 2 level-1 children under first top-level bullet"
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

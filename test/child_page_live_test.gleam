//// Live round-trip for phase-21 child_page recursion. Creates a row
//// in the reference DB, adds a subpage with body content, then fetches
//// the parent with depth=2 and asserts the subpage's content was
//// inlined under the ChildPage block.

import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/erlang/charlist.{type Charlist}
import gleam/http
import gleam/http/request
import gleam/json
import gleam/list
import gleam/option
import gleam/set.{type Set}
import helpers/fixtures
import notion_client
import notion_client/markdown

const title: String = "v3:child-page-read"

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

pub fn child_page_round_trip_live_test() {
  case read_env("NOTION_TOKEN"), read_env("NOTION_BOOTSTRAP_DATABASE_ID") {
    Ok(token), Ok(db_id) -> run(token, db_id)
    _, _ -> Nil
  }
}

fn run(token: String, db_id: String) -> Nil {
  let client = notion_client.new(token)
  fixtures.archive_by_title(client, db_id, title)
  let parent_id = fixtures.create_row(client, db_id, title, [])
  let sub_id = create_subpage(client, parent_id, "Sub Page")
  append_body(client, sub_id, "Hello from sub")
  let tree = fetch_tree(client, parent_id, 0, 2, set.new())
  case find_inlined_child(tree) {
    True -> Nil
    False -> panic as "expected inlined child_page with body content"
  }
}

fn find_inlined_child(blocks: List(markdown.Block)) -> Bool {
  case blocks {
    [] -> False
    [markdown.ChildPage(_, _, _, kids, markdown.Inlined), ..] -> kids != []
    [_, ..rest] -> find_inlined_child(rest)
  }
}

fn create_subpage(
  client: notion_client.Client,
  parent_id: String,
  title: String,
) -> String {
  let body =
    json.object([
      #("parent", json.object([#("page_id", json.string(parent_id))])),
      #(
        "properties",
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
    ])
  post_page(client, body)
}

fn post_page(client: notion_client.Client, body: json.Json) -> String {
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
  max_depth: Int,
  visited: Set(String),
) -> List(markdown.Block) {
  let entries = fetch_children(client, parent_id)
  list.map(entries, fn(entry) {
    let #(block, id, has_children) = entry
    case block {
      markdown.ChildPage(cp_id, title, _, _, _) ->
        resolve_child(client, cp_id, title, depth, max_depth, visited)
      _ ->
        case has_children {
          False -> block
          True ->
            markdown.with_children(
              block,
              fetch_tree(client, id, depth, max_depth, visited),
            )
        }
    }
  })
}

fn resolve_child(
  client: notion_client.Client,
  cp_id: String,
  title: String,
  depth: Int,
  max_depth: Int,
  visited: Set(String),
) -> markdown.Block {
  case set.contains(visited, cp_id) {
    True -> markdown.ChildPage(cp_id, title, depth, [], markdown.CycleDetected)
    False ->
      case depth >= max_depth {
        True ->
          markdown.ChildPage(
            cp_id,
            title,
            depth,
            [],
            markdown.DepthLimitReached,
          )
        False -> {
          let kids =
            fetch_tree(
              client,
              cp_id,
              depth + 1,
              max_depth,
              set.insert(visited, cp_id),
            )
          markdown.ChildPage(cp_id, title, depth + 1, kids, markdown.Inlined)
        }
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

//// Live round-trip for phase-22 child_page write. Creates parent row,
//// pre-creates one existing subpage, then applies a composed markdown
//// with both a `new` create-marker and an existing-id append-marker,
//// and asserts the parent tree contains both subpages with content.

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

pub fn child_page_write_round_trip_live_test() {
  case read_env("NOTION_TOKEN"), read_env("NOTION_BOOTSTRAP_DATABASE_ID") {
    Ok(token), Ok(db_id) -> run(token, db_id)
    _, _ -> Nil
  }
}

fn run(token: String, db_id: String) -> Nil {
  let client = notion_client.new(token)
  let parent = create_row(client, db_id, "phase-22 child-page write")
  let existing = create_subpage(client, parent, "Existing Sub")
  let md =
    "intro line\n"
    <> "<!-- child_page:new -->\n## Fresh Sub\nhello fresh\n"
    <> "<!-- /child_page:new -->\n"
    <> "<!-- child_page:"
    <> existing
    <> " -->\nappended to existing\n<!-- /child_page:"
    <> existing
    <> " -->"
  apply_segments(client, parent, markdown.segment_markdown(md))
  let entries = fetch_children(client, parent)
  case count_child_pages(entries) >= 2 {
    True -> Nil
    False -> panic as "expected 2 child_page blocks under parent"
  }
}

fn count_child_pages(entries: List(#(markdown.Block, String, Bool))) -> Int {
  list.fold(entries, 0, fn(n, e) {
    let #(b, _, _) = e
    case b {
      markdown.ChildPage(_, _, _, _, _) -> n + 1
      _ -> n
    }
  })
}

fn apply_segments(
  client: notion_client.Client,
  parent_id: String,
  segs: List(markdown.WriteSegment),
) -> Nil {
  case segs {
    [] -> Nil
    [s, ..rest] -> {
      apply_one(client, parent_id, s)
      apply_segments(client, parent_id, rest)
    }
  }
}

fn apply_one(
  client: notion_client.Client,
  parent_id: String,
  seg: markdown.WriteSegment,
) -> Nil {
  case seg {
    markdown.PlainMarkdown(md) -> append_md(client, parent_id, md)
    markdown.AppendSubpage(id, body) ->
      apply_segments(client, id, markdown.segment_markdown(body))
    markdown.CreateSubpage(title, body) -> {
      let id = create_subpage(client, parent_id, title)
      apply_segments(client, id, markdown.segment_markdown(body))
    }
  }
}

fn append_md(client: notion_client.Client, page_id: String, md: String) -> Nil {
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
        json.object([#("Name", json.object([#("title", title_rt(title))]))]),
      ),
    ])
  post_page(client, body)
}

fn create_subpage(
  client: notion_client.Client,
  parent_id: String,
  title: String,
) -> String {
  let body =
    json.object([
      #("parent", json.object([#("page_id", json.string(parent_id))])),
      #("properties", json.object([#("title", title_rt(title))])),
    ])
  post_page(client, body)
}

fn title_rt(title: String) -> json.Json {
  json.array([title], fn(t) {
    json.object([
      #("type", json.string("text")),
      #("text", json.object([#("content", json.string(t))])),
    ])
  })
}

fn post_page(client: notion_client.Client, body: json.Json) -> String {
  let req =
    notion_client.base_request(client)
    |> request.set_method(http.Post)
    |> request.set_path("/v1/pages")
    |> request.set_body(<<json.to_string(body):utf8>>)
  let assert Ok(resp) = notion_client.request(client, req)
  assert resp.status == 200
  let id_dec = {
    use id <- decode.field("id", decode.string)
    decode.success(id)
  }
  let assert Ok(id) = json.parse_bits(resp.body, id_dec)
  id
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

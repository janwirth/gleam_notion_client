//// Live round-trip for phase-16: create a fresh row in the reference
//// database, append a paragraph with every supported annotation, fetch
//// the block tree back, and assert the rendered markdown matches.
////
//// Skipped (returns Nil) when `NOTION_TOKEN` or
//// `NOTION_BOOTSTRAP_DATABASE_ID` are unset so CI without secrets stays
//// green.

import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/erlang/charlist.{type Charlist}
import gleam/http
import gleam/http/request
import gleam/json
import gleam/option.{Some}
import gleam/string
import notion_client
import notion_client/markdown
import notion_client/rich_text.{Run}

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

pub fn rich_text_round_trip_live_test() {
  case read_env("NOTION_TOKEN"), read_env("NOTION_BOOTSTRAP_DATABASE_ID") {
    Ok(token), Ok(db_id) -> run(token, db_id)
    _, _ -> Nil
  }
}

fn run(token: String, db_id: String) -> Nil {
  let client = notion_client.new(token)
  let page_id = create_row(client, db_id, "phase-16 rich text")
  let sample = build_sample()
  append_paragraph(client, page_id, sample)
  let blocks = fetch_children(client, page_id)
  let texts = paragraph_texts(blocks)
  assert_contains(texts, "**bold**")
  assert_contains(texts, "*italic*")
  assert_contains(texts, "~~strike~~")
  assert_contains(texts, "`code`")
  assert_contains(texts, "<u>under</u>")
  assert_contains(texts, "[link](")
}

fn build_sample() -> String {
  rich_text.runs_to_markdown([
    rich_text.plain("start "),
    Run(..rich_text.plain("bold"), bold: True),
    rich_text.plain(" "),
    Run(..rich_text.plain("italic"), italic: True),
    rich_text.plain(" "),
    Run(..rich_text.plain("strike"), strikethrough: True),
    rich_text.plain(" "),
    Run(..rich_text.plain("code"), code: True),
    rich_text.plain(" "),
    Run(..rich_text.plain("under"), underline: True),
    rich_text.plain(" "),
    Run(..rich_text.plain("link"), href: Some("https://example.com")),
    rich_text.plain(" end"),
  ])
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

fn append_paragraph(
  client: notion_client.Client,
  page_id: String,
  md: String,
) -> Nil {
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

fn paragraph_texts(blocks: List(markdown.Block)) -> String {
  case blocks {
    [] -> ""
    [markdown.Paragraph(t, _), ..rest] -> t <> "\n" <> paragraph_texts(rest)
    [_, ..rest] -> paragraph_texts(rest)
  }
}

fn assert_contains(haystack: String, needle: String) -> Nil {
  case string.contains(haystack, needle) {
    True -> Nil
    False -> panic as { "live round-trip missing annotation: " <> needle }
  }
}

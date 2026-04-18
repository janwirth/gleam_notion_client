//// Seeds `test/cache/` against the bootstrap Notion page so the
//// decoder test suite (task 10) can run without `NOTION_TOKEN`.
////
//// This file lives in the test tree but is **not** part of the normal
//// `gleam test` run — it short-circuits to `Nil` unless the env var
//// `NOTION_SEED=1` is set. Invoke with:
////
////   NOTION_SEED=1 NOTION_TOKEN=… NOTION_BOOTSTRAP_PAGE_ID=… gleam test
////
//// Walks every reachable endpoint:
////   * users.me, users.list (paginated)
////   * search (empty query, paginated)
////   * pages.retrieve(BOOTSTRAP), blocks.children.list(BOOTSTRAP) →
////     recurse into has_children blocks; for each child_database call
////     databases.retrieve + query_adatabase; for each child_page recurse
////   * comments.list on the root page
////
//// Records a variant inventory (block types + property types seen) and
//// prints it at the end so missing variants can be added to the
//// bootstrap page manually before re-running.

import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/erlang/charlist.{type Charlist}
import gleam/http/request
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import helpers/cached_sender
import notion_client
import notion_client/operations

@external(erlang, "os", "getenv")
fn os_getenv(name: Charlist) -> Dynamic

@external(erlang, "erlang", "is_list")
fn is_list(value: Dynamic) -> Bool

@external(erlang, "erlang", "list_to_binary")
fn list_to_binary(value: Dynamic) -> String

@external(erlang, "erlang", "put")
fn pdict_put(key: a, value: b) -> Dynamic

@external(erlang, "erlang", "get")
fn pdict_get(key: a) -> Dynamic

@external(erlang, "erlang", "erase")
fn pdict_erase(key: a) -> Dynamic

@external(erlang, "test_helpers", "as_string_list")
fn as_string_list(d: Dynamic) -> List(String)

fn read_env(name: String) -> Result(String, Nil) {
  let raw = os_getenv(charlist.from_string(name))
  case is_list(raw) {
    True -> Ok(list_to_binary(raw))
    False -> Error(Nil)
  }
}

fn record_variant(category: String, t: String) -> Nil {
  let key = "seed_inv_" <> category
  let prev = case is_list(pdict_get(key)) {
    True -> as_string_list(pdict_get(key))
    False -> []
  }
  case list.contains(prev, t) {
    True -> Nil
    False -> {
      pdict_put(key, [t, ..prev])
      Nil
    }
  }
}

fn inventory(category: String) -> List(String) {
  let key = "seed_inv_" <> category
  case is_list(pdict_get(key)) {
    True -> as_string_list(pdict_get(key))
    False -> []
  }
}

fn was_visited(category: String, id: String) -> Bool {
  let key = "seed_visited_" <> category
  case is_list(pdict_get(key)) {
    True -> list.contains(as_string_list(pdict_get(key)), id)
    False -> False
  }
}

fn mark_visited(category: String, id: String) -> Nil {
  let key = "seed_visited_" <> category
  let prev = case is_list(pdict_get(key)) {
    True -> as_string_list(pdict_get(key))
    False -> []
  }
  pdict_put(key, [id, ..prev])
  Nil
}

fn reset_state() -> Nil {
  pdict_erase("seed_inv_block")
  pdict_erase("seed_inv_property")
  pdict_erase("seed_visited_page")
  pdict_erase("seed_visited_block")
  Nil
}

pub fn seed_cache_test() {
  case read_env("NOTION_SEED") {
    Ok("1") -> run_seed()
    _ -> Nil
  }
}

fn run_seed() -> Nil {
  let assert Ok(token) = read_env("NOTION_TOKEN")
  let assert Ok(bootstrap) = read_env("NOTION_BOOTSTRAP_PAGE_ID")
  reset_state()

  let client = notion_client.new(token)
  let live = fn(req) { notion_client.send(client, req) }
  let send = cached_sender.wrap(live, cached_sender.Record, "test/cache")
  let base = notion_client.base_request(client)

  io.println("[seed] users.me")
  let _ = send(operations.retrieve_your_token_sbot_user_request(base))

  io.println("[seed] users.list")
  let _ = send(operations.list_all_users_request(base))

  io.println("[seed] search (empty)")
  let _ =
    send(operations.search_request(
      base,
      operations.SearchRequest(query: None, sort: None),
    ))

  io.println("[seed] pages.retrieve(" <> bootstrap <> ")")
  case send(operations.retrieve_apage_request(base, bootstrap)) {
    Ok(resp) -> record_page_properties(resp.body)
    Error(_) -> Nil
  }
  mark_visited("page", bootstrap)

  io.println("[seed] blocks.children.list(" <> bootstrap <> ") + recurse")
  seed_block_children(base, send, bootstrap, 0)

  io.println("[seed] comments.list on root page")
  let _ =
    send(operations.retrieve_comments_request(
      base,
      block_id: Some(bootstrap),
      page_size: None,
    ))

  io.println("---- variant inventory ----")
  io.println("blocks: " <> string.join(inventory("block"), ", "))
  io.println("properties: " <> string.join(inventory("property"), ", "))
  Nil
}

fn seed_block_children(
  base: request.Request(BitArray),
  send: cached_sender.Sender,
  parent_id: String,
  depth: Int,
) -> Nil {
  case depth > 4 {
    True -> Nil
    False ->
      case was_visited("block", parent_id) {
        True -> Nil
        False -> {
          mark_visited("block", parent_id)
          case
            send(operations.retrieve_block_children_request(
              base,
              parent_id,
              None,
            ))
          {
            Error(_) -> Nil
            Ok(resp) -> {
              let blocks = decode_blocks(resp.body)
              list.each(blocks, fn(b) { handle_block(base, send, b, depth) })
            }
          }
        }
      }
  }
}

type SeenBlock {
  SeenBlock(id: String, type_: String, has_children: Bool)
}

fn decode_blocks(body: BitArray) -> List(SeenBlock) {
  let block_decoder = {
    use id <- decode.optional_field("id", "", decode.string)
    use type_ <- decode.optional_field("type", "", decode.string)
    use has_children <- decode.optional_field(
      "has_children",
      False,
      decode.bool,
    )
    decode.success(SeenBlock(id: id, type_: type_, has_children: has_children))
  }
  let outer = {
    use results <- decode.optional_field(
      "results",
      [],
      decode.list(block_decoder),
    )
    decode.success(results)
  }
  case json.parse_bits(body, outer) {
    Ok(blocks) -> blocks
    Error(_) -> []
  }
}

fn handle_block(
  base: request.Request(BitArray),
  send: cached_sender.Sender,
  block: SeenBlock,
  depth: Int,
) -> Nil {
  record_variant("block", block.type_)
  let _ = case block.has_children {
    True -> seed_block_children(base, send, block.id, depth + 1)
    False -> Nil
  }
  case block.type_ {
    "child_database" -> {
      let _ = send(operations.retrieve_adatabase_request(base, block.id))
      let _ =
        send(operations.query_adatabase_request(
          base,
          block.id,
          operations.QueryAdatabaseRequest(filter: None),
        ))
      Nil
    }
    "child_page" ->
      case was_visited("page", block.id) {
        True -> Nil
        False -> {
          mark_visited("page", block.id)
          case send(operations.retrieve_apage_request(base, block.id)) {
            Ok(resp) -> record_page_properties(resp.body)
            Error(_) -> Nil
          }
          seed_block_children(base, send, block.id, depth + 1)
        }
      }
    _ -> Nil
  }
}

fn record_page_properties(body: BitArray) -> Nil {
  let prop_type_decoder = {
    use t <- decode.optional_field("type", "", decode.string)
    decode.success(t)
  }
  let outer = {
    use props <- decode.optional_field(
      "properties",
      [],
      decode.dict(decode.string, prop_type_decoder)
        |> decode.map(fn(d) { d_to_values(d) }),
    )
    decode.success(props)
  }
  case json.parse_bits(body, outer) {
    Ok(types) ->
      list.each(types, fn(t) {
        case t {
          "" -> Nil
          t -> record_variant("property", t)
        }
      })
    Error(_) -> Nil
  }
}

@external(erlang, "test_helpers", "dict_values_strings")
fn d_to_values(d: a) -> List(String)

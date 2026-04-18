//// Tests for `notion_client/pagination`.
////
//// Pure unit tests use a hand-rolled `list_fn` keyed on the cursor
//// string, so they're deterministic and need no fixtures. The
//// end-to-end test wires the helper to a real `notion_client.send`
//// path via `cached_sender`, proving the contract holds against an
//// actual cached Notion response (`blocks.children.list`, single
//// page → `has_more = false`).

import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/http/request
import gleam/http/response.{type Response}
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/yielder
import gleeunit/should
import helpers/cached_sender
import notion_client
import notion_client/error.{
  type NotionError, ClientError, UnknownHttpResponseError,
}
import notion_client/pagination.{type Page, Page, collect, iterate}

pub fn main() {
  Nil
}

// ---------- Pure unit tests ----------

fn three_page_int_fn() -> fn(option.Option(String)) -> Result(Page(Int), String) {
  fn(cursor) {
    case cursor {
      None -> Ok(Page([1, 2], Some("c1")))
      Some("c1") -> Ok(Page([3, 4], Some("c2")))
      Some("c2") -> Ok(Page([5], None))
      Some(other) -> Error("unexpected cursor: " <> other)
    }
  }
}

pub fn collect_walks_all_pages_test() {
  let assert Ok(items) = collect(three_page_int_fn())
  items |> should.equal([1, 2, 3, 4, 5])
}

pub fn iterate_yields_all_items_in_order_test() {
  let items = three_page_int_fn() |> iterate |> yielder.to_list
  items |> should.equal([Ok(1), Ok(2), Ok(3), Ok(4), Ok(5)])
}

pub fn collect_single_page_test() {
  let single = fn(_cursor) { Ok(Page([10, 20, 30], None)) }
  let assert Ok(items) = collect(single)
  items |> should.equal([10, 20, 30])
}

pub fn iterate_single_page_test() {
  let single = fn(_cursor) { Ok(Page([10, 20], None)) }
  let items = iterate(single) |> yielder.to_list
  items |> should.equal([Ok(10), Ok(20)])
}

pub fn collect_empty_results_test() {
  let empty = fn(_cursor) { Ok(Page([], None)) }
  let assert Ok(items) = collect(empty)
  items |> should.equal([])
}

pub fn iterate_empty_results_test() {
  let empty = fn(_cursor) { Ok(Page([], None)) }
  iterate(empty) |> yielder.to_list |> should.equal([])
}

pub fn collect_propagates_error_on_first_page_test() {
  let bad = fn(_cursor) { Error("boom") }
  collect(bad) |> should.equal(Error("boom"))
}

pub fn collect_propagates_error_mid_walk_test() {
  let mid = fn(cursor) {
    case cursor {
      None -> Ok(Page([1, 2], Some("c1")))
      _ -> Error("network died")
    }
  }
  collect(mid) |> should.equal(Error("network died"))
}

pub fn iterate_propagates_error_then_halts_test() {
  let mid = fn(cursor) {
    case cursor {
      None -> Ok(Page([1], Some("c1")))
      _ -> Error("network died")
    }
  }
  let out = iterate(mid) |> yielder.to_list
  out |> should.equal([Ok(1), Error("network died")])
}

// ---------- Laziness ----------
//
// Use the process dictionary to count how many times `list_fn` is
// invoked. `iterate |> take 2 |> to_list` should fetch only the first
// page when the first page already contains 2 items.

@external(erlang, "erlang", "put")
fn pdict_put(key: a, value: b) -> Dynamic

@external(erlang, "erlang", "get")
fn pdict_get(key: a) -> Dynamic

@external(erlang, "erlang", "erase")
fn pdict_erase(key: a) -> Dynamic

@external(erlang, "test_helpers", "to_int")
fn raw_to_int(value: Dynamic) -> Int

const count_key: String = "pagination_test_call_count"

fn reset_count() {
  let _ = pdict_erase(count_key)
  Nil
}

fn bump_count() {
  let raw = pdict_get(count_key)
  let prev = case dynamic.classify(raw) == "Int" {
    True -> raw_to_int(raw)
    False -> 0
  }
  let _ = pdict_put(count_key, prev + 1)
  Nil
}

fn read_count() -> Int {
  let raw = pdict_get(count_key)
  case dynamic.classify(raw) == "Int" {
    True -> raw_to_int(raw)
    False -> 0
  }
}

pub fn iterate_is_lazy_test() {
  reset_count()
  let counting = fn(cursor) {
    bump_count()
    case cursor {
      None -> Ok(Page([1, 2], Some("c1")))
      Some("c1") -> Ok(Page([3, 4], Some("c2")))
      Some("c2") -> Ok(Page([5], None))
      Some(_) -> Error("unexpected")
    }
  }
  let first_two = counting |> iterate |> yielder.take(2) |> yielder.to_list
  first_two |> should.equal([Ok(1), Ok(2)])
  read_count() |> should.equal(1)
}

// ---------- End-to-end against cached blocks.children.list ----------

const block_id: String = "3465cbd3c0c680d7bcc2f8dd15b3a05d"

pub fn collect_blocks_children_against_cache_test() {
  let client = notion_client.new("test-token")
  let sender =
    cached_sender.wrap(
      fn(req) { notion_client.send(client, req) },
      cached_sender.Replay,
      cached_sender.default_root,
    )

  let list_fn = fn(_cursor) {
    // The cached fixture has `has_more = false`, so the cursor is
    // unused. A production list_fn would inject `start_cursor` into
    // the request's query string here.
    let req = build_blocks_children_request(client)
    case sender(req) {
      Error(_) -> Error(ClientError(UnknownHttpResponseError("cache miss")))
      Ok(resp) -> decode_blocks_page(resp)
    }
  }

  let assert Ok(items) = collect(list_fn)
  // The seeded page has at least one block (an embed).
  case list.length(items) {
    n if n >= 1 -> Nil
    _ -> panic as "expected ≥1 cached block child"
  }
}

fn build_blocks_children_request(client) {
  notion_client.base_request(client)
  |> request.set_path("/v1/blocks/" <> block_id <> "/children")
}

fn decode_blocks_page(
  resp: Response(BitArray),
) -> Result(Page(Dynamic), NotionError) {
  let item_decoder = {
    use raw <- decode.then(decode.dynamic)
    decode.success(raw)
  }
  let page_decoder = {
    use results <- decode.optional_field(
      "results",
      [],
      decode.list(item_decoder),
    )
    use next_cursor <- decode.optional_field(
      "next_cursor",
      None,
      decode.optional(decode.string),
    )
    decode.success(Page(items: results, next_cursor: next_cursor))
  }
  case json.parse_bits(resp.body, page_decoder) {
    Ok(page) -> Ok(page)
    Error(_) ->
      Error(ClientError(UnknownHttpResponseError("failed to decode page")))
  }
}

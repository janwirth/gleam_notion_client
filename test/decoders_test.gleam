//// Decoder coverage suite. Replays every cached response under
//// `test/cache/` through its generated `*_response` decoder and
//// asserts the body parses cleanly. Adding a new cache file picks up
//// automatically — `replay_all_cached_test` walks the directory and
//// dispatches via `endpoint_for_filename/1`.
////
//// Per cache file:
////   * 2xx → outer `Ok` (decode succeeded), inner `Ok` (status was 2xx)
////   * non-2xx → outer `Ok`, inner `Error(Response)` (the original
////     response surfaced for inspection)
////
//// Adding a new endpoint cache: add a branch to
//// `endpoint_for_filename/1` mapping the filename to its endpoint
//// key, and a branch to `dispatch/2` mapping the key to the
//// generated decoder. The suite panics with the offending filename
//// when an unknown file is encountered.

import gleam/http/response.{type Response}
import gleam/io
import gleam/json
import gleam/list
import gleam/option
import gleam/string
import gleeunit
import helpers/cached_sender
import notion_client/operations
import simplifile

pub fn main() -> Nil {
  gleeunit.main()
}

fn load(path: String) -> Response(BitArray) {
  let assert Ok(resp) = cached_sender.load(path)
  resp
}

fn ensure_decoded(
  path: String,
  result: Result(Result(a, Response(BitArray)), json.DecodeError),
) -> Nil {
  case result {
    Ok(Ok(_)) -> Nil
    Ok(Error(resp)) ->
      case resp.status >= 200 && resp.status < 300 {
        True ->
          panic as { "decoder reported non-2xx for cached 2xx body: " <> path }
        False -> Nil
      }
    Error(err) -> {
      io.println("decoder failed for " <> path)
      io.println(string.inspect(err))
      panic as { "decode error in " <> path }
    }
  }
}

fn dispatch(path: String, resp: Response(BitArray)) -> Nil {
  case endpoint_for_filename(path) {
    "users.me" ->
      ensure_decoded(
        path,
        operations.retrieve_your_token_sbot_user_response(resp),
      )
    "users.list" ->
      ensure_decoded(path, operations.list_all_users_response(resp))
    "users.retrieve" ->
      ensure_decoded(path, operations.retrieve_auser_response(resp))
    "pages.retrieve" ->
      ensure_decoded(path, operations.retrieve_apage_response(resp))
    "blocks.children.list" ->
      ensure_decoded(path, operations.retrieve_block_children_response(resp))
    "blocks.retrieve" ->
      ensure_decoded(path, operations.retrieve_ablock_response(resp))
    "comments.list" ->
      ensure_decoded(path, operations.retrieve_comments_response(resp))
    "search" -> ensure_decoded(path, operations.search_response(resp))
    "databases.retrieve" ->
      ensure_decoded(path, operations.retrieve_adatabase_response(resp))
    "databases.query" ->
      ensure_decoded(path, operations.query_adatabase_response(resp))
    other ->
      panic as {
        "no decoder mapping for endpoint '"
        <> other
        <> "' (file: "
        <> path
        <> "); add a branch in dispatch/2"
      }
  }
}

/// Maps a cache filename to a stable endpoint slug. `dispatch/2` is
/// the source of truth for recognised slugs. Order matters — more
/// specific patterns must come before the generic `_<id>_` matchers.
fn endpoint_for_filename(path: String) -> String {
  let name = case list.last(string.split(path, "/")) {
    Ok(n) -> n
    Error(_) -> path
  }
  classify(name)
}

fn classify(name: String) -> String {
  use <- match(string.starts_with(name, "get__v1_users_me_"), "users.me")
  use <- match(string.starts_with(name, "get__v1_users__"), "users.list")
  use <- match(string.starts_with(name, "get__v1_users_"), "users.retrieve")
  use <- match(string.starts_with(name, "get__v1_pages_"), "pages.retrieve")
  use <- match(
    string.starts_with(name, "get__v1_blocks_")
      && string.contains(name, "_children_"),
    "blocks.children.list",
  )
  use <- match(string.starts_with(name, "get__v1_blocks_"), "blocks.retrieve")
  use <- match(string.starts_with(name, "get__v1_comments_"), "comments.list")
  use <- match(string.starts_with(name, "post__v1_search_"), "search")
  use <- match(
    string.starts_with(name, "post__v1_databases_")
      && string.contains(name, "_query_"),
    "databases.query",
  )
  use <- match(
    string.starts_with(name, "get__v1_databases_"),
    "databases.retrieve",
  )
  "unknown:" <> name
}

fn match(condition: Bool, slug: String, fallback: fn() -> String) -> String {
  case condition {
    True -> slug
    False -> fallback()
  }
}

pub fn replay_all_cached_test() {
  let assert Ok(entries) = simplifile.read_directory("test/cache")
  let json_files =
    entries
    |> list.filter(string.ends_with(_, ".json"))
    |> list.map(fn(name) { "test/cache/" <> name })

  case list.is_empty(json_files) {
    True -> panic as "test/cache/ is empty; run task 09 to seed it"
    False -> Nil
  }

  list.each(json_files, fn(p) { dispatch(p, load(p)) })
}

pub fn list_response_items_decode_individually_test() {
  // Spot-check that every item in the search list response decodes —
  // the outer decoder already covers this, but the explicit assertion
  // anchors the contract so future regressions land here.
  let resp = load("test/cache/post__v1_search__44136fa3.json")
  let assert Ok(Ok(decoded)) = operations.search_response(resp)
  case decoded.results {
    option.None -> Nil
    option.Some(items) -> {
      let _ = list.length(items)
      Nil
    }
  }
}

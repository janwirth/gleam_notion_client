//// Smoke tests for the hand-written endpoint facades.
////
//// These tests prove two things per facade:
////   1. The request the facade builds via `operations.*_request`
////      matches the cache key for the seeded fixture (so the
////      production transport would hit the cache in `Replay` mode).
////   2. The response decoder accepts the cached body and returns the
////      typed variant.
////
//// Facades for endpoints without a cached fixture (databases.*,
//// blocks non-children, pages.create/update, comments.create) are
//// referenced via `_facade_refs` so accidental removal is a build
//// error. End-to-end live exercise lives in `seed_cache_test`.

import gleam/option.{None, Some}
import gleeunit/should
import helpers/cached_sender
import notion_client
import notion_client/blocks
import notion_client/blocks/children as block_children
import notion_client/comments
import notion_client/databases
import notion_client/operations
import notion_client/pages
import notion_client/search as search_facade
import notion_client/users

pub fn main() {
  Nil
}

const block_id: String = "3465cbd3c0c680d7bcc2f8dd15b3a05d"

const page_id: String = "3465cbd3c0c680d7bcc2f8dd15b3a05d"

fn client() -> notion_client.Client {
  notion_client.new("test-token")
}

pub fn users_me_facade_request_and_decode_test() {
  let req =
    notion_client.base_request(client())
    |> operations.retrieve_your_token_sbot_user_request
  let path = cached_sender.path_for(req, cached_sender.default_root)
  path |> should.equal("test/cache/get__v1_users_me__e3b0c442.json")
  let assert Ok(resp) = cached_sender.load(path)
  let assert Ok(Ok(_)) = operations.retrieve_your_token_sbot_user_response(resp)
  Nil
}

pub fn users_list_facade_request_shape_test() {
  let req =
    notion_client.base_request(client())
    |> operations.list_all_users_request
  cached_sender.key(req)
  |> should.equal("get__v1_users__e3b0c442")
}

pub fn users_retrieve_facade_request_shape_test() {
  let req =
    notion_client.base_request(client())
    |> operations.retrieve_auser_request("user-123")
  cached_sender.key(req)
  |> should.equal("get__v1_users_user-123__e3b0c442")
}

pub fn pages_retrieve_facade_request_and_decode_test() {
  let req =
    notion_client.base_request(client())
    |> operations.retrieve_apage_request(page_id)
  let path = cached_sender.path_for(req, cached_sender.default_root)
  path
  |> should.equal(
    "test/cache/get__v1_pages_3465cbd3c0c680d7bcc2f8dd15b3a05d__e3b0c442.json",
  )
  let assert Ok(resp) = cached_sender.load(path)
  let assert Ok(Ok(_)) = operations.retrieve_apage_response(resp)
  Nil
}

pub fn block_children_list_facade_request_and_decode_test() {
  let req =
    notion_client.base_request(client())
    |> operations.retrieve_block_children_request(block_id, page_size: None)
  let path = cached_sender.path_for(req, cached_sender.default_root)
  path
  |> should.equal(
    "test/cache/get__v1_blocks_3465cbd3c0c680d7bcc2f8dd15b3a05d_children__e3b0c442.json",
  )
  let assert Ok(resp) = cached_sender.load(path)
  let assert Ok(Ok(_)) = operations.retrieve_block_children_response(resp)
  Nil
}

pub fn comments_list_facade_request_shape_test() {
  let req =
    notion_client.base_request(client())
    |> operations.retrieve_comments_request(
      block_id: Some(block_id),
      page_size: None,
    )
  cached_sender.key(req)
  |> should.equal(
    "get__v1_comments_block_id_3465cbd3c0c680d7bcc2f8dd15b3a05d_e3b0c442",
  )
}

pub fn search_facade_request_and_decode_test() {
  let body = operations.SearchRequest(query: None, sort: None)
  let req =
    notion_client.base_request(client())
    |> operations.search_request(body)
  cached_sender.key(req)
  |> should.equal("post__v1_search__44136fa3")
  let path = cached_sender.path_for(req, cached_sender.default_root)
  let assert Ok(resp) = cached_sender.load(path)
  let assert Ok(Ok(_)) = operations.search_response(resp)
  Nil
}

/// Touch every facade function so the facade modules cannot be
/// silently removed without a build break. Each entry is a `fn`
/// reference — none of them execute under test.
pub fn facade_refs_compile_test() {
  let _ = users.me
  let _ = users.list
  let _ = users.retrieve
  let _ = pages.create
  let _ = pages.retrieve
  let _ = pages.update
  let _ = pages.properties_retrieve
  let _ = databases.query
  let _ = databases.retrieve
  let _ = databases.create
  let _ = databases.update
  let _ = blocks.retrieve
  let _ = blocks.update
  let _ = blocks.delete
  let _ = block_children.list
  let _ = block_children.append
  let _ = comments.create
  let _ = comments.list
  let _ = search_facade.search
  Nil
}

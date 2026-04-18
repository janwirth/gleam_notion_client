//// Tests for `notion_client/guards`. Cached fixtures provide the
//// "full" cases; partial cases are constructed inline because the
//// API rarely returns partial top-level responses (partials usually
//// nest inside `parent`/`created_by`).

import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import helpers/cached_sender
import notion_client/guards
import notion_client/operations.{
  type RetrieveAuserResponse, Anon2d4a475d, AnonE3efa372, RetrieveAblockResponse,
  RetrieveApageResponse, RetrieveAuserResponse,
}

pub fn main() {
  Nil
}

// ---------- Bot user (cached users.me) ----------

pub fn is_full_bot_user_on_cached_me_test() {
  let assert Ok(resp) =
    cached_sender.load("test/cache/get__v1_users_me__e3b0c442.json")
  let assert Ok(Ok(user)) =
    operations.retrieve_your_token_sbot_user_response(resp)
  guards.is_full_bot_user(user) |> should.equal(True)
  case guards.as_full_bot_user(user) {
    Some(_) -> Nil
    None -> panic as "expected Some(full bot user)"
  }
}

// ---------- User ----------

fn full_user() -> RetrieveAuserResponse {
  RetrieveAuserResponse(
    avatar_url: None,
    id: Some("u-1"),
    name: Some("Alice"),
    object: Some("user"),
    person: None,
    type_: Some("person"),
  )
}

fn partial_user() -> RetrieveAuserResponse {
  RetrieveAuserResponse(
    avatar_url: None,
    id: Some("u-1"),
    name: None,
    object: None,
    person: None,
    type_: None,
  )
}

pub fn is_full_user_returns_true_on_full_record_test() {
  guards.is_full_user(full_user()) |> should.equal(True)
}

pub fn is_full_user_returns_false_on_partial_record_test() {
  guards.is_full_user(partial_user()) |> should.equal(False)
}

pub fn as_full_user_narrows_test() {
  guards.as_full_user(full_user()) |> should.equal(Some(full_user()))
  guards.as_full_user(partial_user()) |> should.equal(None)
}

// ---------- Page (cached pages.retrieve) ----------

pub fn is_full_page_on_cached_page_test() {
  let assert Ok(resp) =
    cached_sender.load(
      "test/cache/get__v1_pages_3465cbd3c0c680d7bcc2f8dd15b3a05d__e3b0c442.json",
    )
  let assert Ok(Ok(page)) = operations.retrieve_apage_response(resp)
  guards.is_full_page(page) |> should.equal(True)
}

pub fn is_full_page_on_partial_record_test() {
  let partial =
    RetrieveApageResponse(
      archived: None,
      cover: None,
      created_by: None,
      created_time: None,
      icon: None,
      id: Some("p-1"),
      last_edited_by: None,
      last_edited_time: None,
      object: Some("page"),
      parent: None,
      properties: None,
      url: None,
    )
  guards.is_full_page(partial) |> should.equal(False)
  guards.as_full_page(partial) |> should.equal(None)
}

// ---------- Block ----------

pub fn is_full_block_on_partial_record_test() {
  let partial =
    RetrieveAblockResponse(
      created_time: None,
      has_children: None,
      id: Some("b-1"),
      last_edited_time: None,
      object: Some("block"),
      paragraph: None,
      type_: None,
    )
  guards.is_full_block(partial) |> should.equal(False)
}

pub fn is_full_block_item_on_cached_children_test() {
  let assert Ok(resp) =
    cached_sender.load(
      "test/cache/get__v1_blocks_3465cbd3c0c680d7bcc2f8dd15b3a05d_children__e3b0c442.json",
    )
  let assert Ok(Ok(children)) =
    operations.retrieve_block_children_response(resp)
  let items = case children.results {
    Some(xs) -> xs
    None -> []
  }
  case list.first(items) {
    Ok(first) -> guards.is_full_block_item(first) |> should.equal(True)
    Error(_) -> panic as "cached children list is empty; reseed cache"
  }
}

pub fn is_full_block_item_on_partial_record_test() {
  let partial =
    AnonE3efa372(
      created_time: None,
      has_children: None,
      id: Some("b-1"),
      last_edited_time: None,
      object: Some("block"),
      paragraph: None,
      type_: None,
      unsupported: None,
    )
  guards.is_full_block_item(partial) |> should.equal(False)
}

// ---------- Comment ----------

pub fn is_full_comment_on_partial_record_test() {
  let partial =
    Anon2d4a475d(
      created_by: None,
      created_time: None,
      discussion_id: Some("d-1"),
      id: Some("c-1"),
      last_edited_time: None,
      object: Some("comment"),
      parent: None,
      rich_text: None,
    )
  guards.is_full_comment(partial) |> should.equal(False)
  guards.as_full_comment(partial) |> should.equal(None)
}

pub fn is_full_comment_on_full_record_test() {
  let full =
    Anon2d4a475d(
      created_by: None,
      created_time: Some("2025-01-01T00:00:00.000Z"),
      discussion_id: Some("d-1"),
      id: Some("c-1"),
      last_edited_time: Some("2025-01-01T00:00:00.000Z"),
      object: Some("comment"),
      parent: Some(operations.Anon8882a242(block_id: Some("b-1"), type_: None)),
      rich_text: Some([]),
    )
  guards.is_full_comment(full) |> should.equal(True)
}

//// Full/partial type guards. Notion's API sometimes returns
//// "partial" objects (just `{ id, object }`) instead of fully-hydrated
//// records — typically inside `parent`, `created_by`,
//// `last_edited_by`, or when the integration lacks read access. The
//// JS SDK exposes `isFullPage`, `isFullBlock`, etc. for runtime
//// narrowing; this module mirrors that surface.
////
//// Because the generated types make every field `Option(_)` (the
//// OpenAPI source is loose about required fields), "full" here means
//// the discriminator fields that only appear on hydrated responses
//// are all `Some`. When a guard returns `True`, callers can treat the
//// record as fully hydrated; when `False`, only `id`/`object` should
//// be relied upon.
////
//// `is_full_data_source` is omitted: the generated module is built
//// from the v1 Postman collection, which does not include the
//// `data_sources` namespace. Add it if/when those types are
//// generated.

import gleam/option.{type Option, None, Some}
import notion_client/operations.{
  type AddCommentToPageResponse, type Anon2d4a475d, type AnonE3efa372,
  type RetrieveAblockResponse, type RetrieveApageResponse,
  type RetrieveAuserResponse, type RetrieveYourTokenSbotUserResponse,
}

/// True when `user` carries the discriminator fields a hydrated
/// `users.retrieve` response always returns: `id`, `type`, `object`.
pub fn is_full_user(user: RetrieveAuserResponse) -> Bool {
  all_some3(user.id, user.type_, user.object)
}

/// `Some(user)` when full, `None` otherwise. Use to refine a value
/// before passing it on; semantics match `is_full_user` exactly.
pub fn as_full_user(
  user: RetrieveAuserResponse,
) -> Option(RetrieveAuserResponse) {
  case is_full_user(user) {
    True -> Some(user)
    False -> None
  }
}

/// True when `user` (the bot user from `users.me`) is fully
/// hydrated. Same discriminators as `is_full_user`.
pub fn is_full_bot_user(user: RetrieveYourTokenSbotUserResponse) -> Bool {
  all_some3(user.id, user.type_, user.object)
}

pub fn as_full_bot_user(
  user: RetrieveYourTokenSbotUserResponse,
) -> Option(RetrieveYourTokenSbotUserResponse) {
  case is_full_bot_user(user) {
    True -> Some(user)
    False -> None
  }
}

/// True when `page` carries the fields only present on a fully
/// hydrated page response: `id`, `created_time`, `last_edited_time`,
/// `properties`.
pub fn is_full_page(page: RetrieveApageResponse) -> Bool {
  all_some4(page.id, page.created_time, page.last_edited_time, page.properties)
}

pub fn as_full_page(
  page: RetrieveApageResponse,
) -> Option(RetrieveApageResponse) {
  case is_full_page(page) {
    True -> Some(page)
    False -> None
  }
}

/// True when `block` (single-block response) is fully hydrated:
/// `id`, `type`, `created_time`, `last_edited_time` are all `Some`.
pub fn is_full_block(block: RetrieveAblockResponse) -> Bool {
  all_some4(block.id, block.type_, block.created_time, block.last_edited_time)
}

pub fn as_full_block(
  block: RetrieveAblockResponse,
) -> Option(RetrieveAblockResponse) {
  case is_full_block(block) {
    True -> Some(block)
    False -> None
  }
}

/// True when an item from `blocks/children.list.results` is fully
/// hydrated. Same discriminators as `is_full_block` — the field set
/// is identical, just typed as the anonymous list-item record.
pub fn is_full_block_item(block: AnonE3efa372) -> Bool {
  all_some4(block.id, block.type_, block.created_time, block.last_edited_time)
}

pub fn as_full_block_item(block: AnonE3efa372) -> Option(AnonE3efa372) {
  case is_full_block_item(block) {
    True -> Some(block)
    False -> None
  }
}

/// True when an item from `comments.list.results` is fully hydrated:
/// `id`, `created_time`, `parent`, `rich_text` all `Some`.
pub fn is_full_comment(comment: Anon2d4a475d) -> Bool {
  all_some4(comment.id, comment.created_time, comment.parent, comment.rich_text)
}

pub fn as_full_comment(comment: Anon2d4a475d) -> Option(Anon2d4a475d) {
  case is_full_comment(comment) {
    True -> Some(comment)
    False -> None
  }
}

/// True when a `comments.create` response is fully hydrated. Same
/// discriminators as `is_full_comment`.
pub fn is_full_comment_response(comment: AddCommentToPageResponse) -> Bool {
  all_some4(comment.id, comment.created_time, comment.parent, comment.rich_text)
}

pub fn as_full_comment_response(
  comment: AddCommentToPageResponse,
) -> Option(AddCommentToPageResponse) {
  case is_full_comment_response(comment) {
    True -> Some(comment)
    False -> None
  }
}

fn all_some3(a: Option(_), b: Option(_), c: Option(_)) -> Bool {
  case a, b, c {
    Some(_), Some(_), Some(_) -> True
    _, _, _ -> False
  }
}

fn all_some4(a: Option(_), b: Option(_), c: Option(_), d: Option(_)) -> Bool {
  case a, b, c, d {
    Some(_), Some(_), Some(_), Some(_) -> True
    _, _, _, _ -> False
  }
}

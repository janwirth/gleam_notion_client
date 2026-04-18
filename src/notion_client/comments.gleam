//// Comments facade — mirrors `notion_client.comments.*` in the JS SDK.

import gleam/option.{type Option}
import notion_client.{type Client}
import notion_client/error.{type NotionError}
import notion_client/internal/facade
import notion_client/operations.{
  type AddCommentToPageRequest, type AddCommentToPageResponse,
  type RetrieveCommentsResponse,
}

/// `POST /v1/comments` — add a comment to a page or thread.
pub fn create(
  client: Client,
  body: AddCommentToPageRequest,
) -> Result(AddCommentToPageResponse, NotionError) {
  let req =
    notion_client.base_request(client)
    |> operations.add_comment_to_page_request(body)
  facade.run(client, req, operations.add_comment_to_page_response)
}

/// `GET /v1/comments` — list comments under a block. The generated
/// request builder takes `block_id` and `page_size` as query params
/// (Notion expects them on the URL, not in a body).
pub fn list(
  client: Client,
  block_id block_id: Option(String),
  page_size page_size: Option(String),
) -> Result(RetrieveCommentsResponse, NotionError) {
  let req =
    notion_client.base_request(client)
    |> operations.retrieve_comments_request(
      block_id: block_id,
      page_size: page_size,
    )
  facade.run(client, req, operations.retrieve_comments_response)
}

//// Block children facade — mirrors `notion_client.blocks.children.*`
//// in the JS SDK. Pair with [`notion_client/pagination`](../pagination.html)
//// for full cursor walks.

import gleam/option.{type Option}
import notion_client.{type Client}

import notion_client/error.{type NotionError}
import notion_client/internal/facade
import notion_client/operations.{
  type AppendBlockChildrenRequest, type AppendBlockChildrenResponse,
  type RetrieveBlockChildrenResponse,
}

/// `GET /v1/blocks/<id>/children` — first page of a block's
/// children. The generated request builder only exposes `page_size`,
/// not `start_cursor`; for cursor walks, build the request manually
/// and inject `start_cursor` into the query string.
pub fn list(
  client: Client,
  id: String,
  page_size page_size: Option(String),
) -> Result(RetrieveBlockChildrenResponse, NotionError) {
  let req =
    notion_client.base_request(client)
    |> operations.retrieve_block_children_request(id, page_size: page_size)
  facade.run(client, req, operations.retrieve_block_children_response)
}

/// `PATCH /v1/blocks/<id>/children` — append children to an existing
/// block.
pub fn append(
  client: Client,
  id: String,
  body: AppendBlockChildrenRequest,
) -> Result(AppendBlockChildrenResponse, NotionError) {
  let req =
    notion_client.base_request(client)
    |> operations.append_block_children_request(id, body)
  facade.run(client, req, operations.append_block_children_response)
}

//// Blocks facade — mirrors `notion_client.blocks.*` in the JS SDK.
//// `children.list` and `children.append` live in
//// `notion_client/blocks/children`.

import notion_client.{type Client}
import notion_client/error.{type NotionError}
import notion_client/internal/facade
import notion_client/operations.{
  type DeleteAblockResponse, type RetrieveAblockResponse,
  type UpdateAblockRequest, type UpdateAblockResponse,
}

/// `GET /v1/blocks/<id>` — single block (no children traversal).
pub fn retrieve(
  client: Client,
  id: String,
) -> Result(RetrieveAblockResponse, NotionError) {
  let req =
    notion_client.base_request(client)
    |> operations.retrieve_ablock_request(id)
  facade.run(client, req, operations.retrieve_ablock_response)
}

/// `PATCH /v1/blocks/<id>` — update block content (currently only
/// `paragraph` is exposed by the generated request builder).
pub fn update(
  client: Client,
  id: String,
  body: UpdateAblockRequest,
) -> Result(UpdateAblockResponse, NotionError) {
  let req =
    notion_client.base_request(client)
    |> operations.update_ablock_request(id, body)
  facade.run(client, req, operations.update_ablock_response)
}

/// `DELETE /v1/blocks/<id>` — soft-delete (Notion archives, not
/// hard-deletes).
pub fn delete(
  client: Client,
  id: String,
) -> Result(DeleteAblockResponse, NotionError) {
  let req =
    notion_client.base_request(client)
    |> operations.delete_ablock_request(id)
  facade.run(client, req, operations.delete_ablock_response)
}

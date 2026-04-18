//// Pages facade — mirrors `notion_client.pages.*` in the JS SDK.

import notion_client.{type Client}
import notion_client/error.{type NotionError}
import notion_client/internal/facade
import notion_client/operations.{
  type CreateApageRequest, type CreateApageResponse,
  type RetrieveApagePropertyItemResponse, type RetrieveApageResponse,
  type UpdatePagePropertiesRequest, type UpdatePagePropertiesResponse,
}

/// `POST /v1/pages` — create a page from a parent + properties block.
pub fn create(
  client: Client,
  body: CreateApageRequest,
) -> Result(CreateApageResponse, NotionError) {
  let req =
    notion_client.base_request(client)
    |> operations.create_apage_request(body)
  facade.run(client, req, operations.create_apage_response)
}

/// `GET /v1/pages/<id>` — single page metadata + properties.
pub fn retrieve(
  client: Client,
  id: String,
) -> Result(RetrieveApageResponse, NotionError) {
  let req =
    notion_client.base_request(client)
    |> operations.retrieve_apage_request(id)
  facade.run(client, req, operations.retrieve_apage_response)
}

/// `PATCH /v1/pages/<id>` — update top-level properties (currently
/// only `archived` is exposed by the generated request builder; other
/// properties land via `update_page_properties_request` future regen).
pub fn update(
  client: Client,
  id: String,
  body: UpdatePagePropertiesRequest,
) -> Result(UpdatePagePropertiesResponse, NotionError) {
  let req =
    notion_client.base_request(client)
    |> operations.update_page_properties_request(id, body)
  facade.run(client, req, operations.update_page_properties_response)
}

/// `GET /v1/pages/<page_id>/properties/<property_id>` — single
/// property value, paginated for list-typed properties.
pub fn properties_retrieve(
  client: Client,
  page_id: String,
  property_id: String,
) -> Result(RetrieveApagePropertyItemResponse, NotionError) {
  let req =
    notion_client.base_request(client)
    |> operations.retrieve_apage_property_item_request(page_id, property_id)
  facade.run(client, req, operations.retrieve_apage_property_item_response)
}

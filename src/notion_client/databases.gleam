//// Databases facade — mirrors `notion_client.databases.*` in the JS
//// SDK. Notion exposes the same surface under both `databases` (v1)
//// and `data_sources` (v2); the generated module is built from the
//// v1 Postman collection so this facade covers v1.

import notion_client.{type Client}
import notion_client/error.{type NotionError}
import notion_client/internal/facade
import notion_client/operations.{
  type CreateAdatabaseRequest, type CreateAdatabaseResponse,
  type QueryAdatabaseRequest, type QueryAdatabaseResponse,
  type RetrieveAdatabaseResponse, type UpdateAdatabaseRequest,
  type UpdateAdatabaseResponse,
}

/// `POST /v1/databases/<id>/query` — paginated query over a database.
pub fn query(
  client: Client,
  id: String,
  body: QueryAdatabaseRequest,
) -> Result(QueryAdatabaseResponse, NotionError) {
  let req =
    notion_client.base_request(client)
    |> operations.query_adatabase_request(id, body)
  facade.run(client, req, operations.query_adatabase_response)
}

/// `GET /v1/databases/<id>` — schema + metadata for one database.
pub fn retrieve(
  client: Client,
  id: String,
) -> Result(RetrieveAdatabaseResponse, NotionError) {
  let req =
    notion_client.base_request(client)
    |> operations.retrieve_adatabase_request(id)
  facade.run(client, req, operations.retrieve_adatabase_response)
}

/// `POST /v1/databases` — create a new database under a parent page.
pub fn create(
  client: Client,
  body: CreateAdatabaseRequest,
) -> Result(CreateAdatabaseResponse, NotionError) {
  let req =
    notion_client.base_request(client)
    |> operations.create_adatabase_request(body)
  facade.run(client, req, operations.create_adatabase_response)
}

/// `PATCH /v1/databases/<id>` — update database title or properties.
pub fn update(
  client: Client,
  id: String,
  body: UpdateAdatabaseRequest,
) -> Result(UpdateAdatabaseResponse, NotionError) {
  let req =
    notion_client.base_request(client)
    |> operations.update_adatabase_request(id, body)
  facade.run(client, req, operations.update_adatabase_response)
}

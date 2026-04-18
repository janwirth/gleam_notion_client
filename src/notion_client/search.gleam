//// Search facade — `POST /v1/search`. Mirrors `notion_client.search`
//// in the JS SDK.

import notion_client.{type Client}
import notion_client/error.{type NotionError}
import notion_client/internal/facade
import notion_client/operations.{type SearchRequest, type SearchResponse}

/// Search across pages + databases the integration can access.
/// Pass an empty `SearchRequest(query: None, sort: None)` to list
/// everything.
pub fn search(
  client: Client,
  body: SearchRequest,
) -> Result(SearchResponse, NotionError) {
  let req =
    notion_client.base_request(client)
    |> operations.search_request(body)
  facade.run(client, req, operations.search_response)
}

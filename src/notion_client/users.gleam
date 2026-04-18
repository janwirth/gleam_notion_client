//// Users facade — mirrors `notion_client.users.*` in the JS SDK.

import notion_client.{type Client}
import notion_client/error.{type NotionError}
import notion_client/internal/facade
import notion_client/operations.{
  type ListAllUsersResponse, type RetrieveAuserResponse,
  type RetrieveYourTokenSbotUserResponse,
}

/// `GET /v1/users/me` — bot user for the integration token.
pub fn me(
  client: Client,
) -> Result(RetrieveYourTokenSbotUserResponse, NotionError) {
  let req =
    notion_client.base_request(client)
    |> operations.retrieve_your_token_sbot_user_request
  facade.run(client, req, operations.retrieve_your_token_sbot_user_response)
}

/// `GET /v1/users` — first page of workspace users.
pub fn list(client: Client) -> Result(ListAllUsersResponse, NotionError) {
  let req =
    notion_client.base_request(client)
    |> operations.list_all_users_request
  facade.run(client, req, operations.list_all_users_response)
}

/// `GET /v1/users/<id>` — single user by id.
pub fn retrieve(
  client: Client,
  id: String,
) -> Result(RetrieveAuserResponse, NotionError) {
  let req =
    notion_client.base_request(client)
    |> operations.retrieve_auser_request(id)
  facade.run(client, req, operations.retrieve_auser_response)
}

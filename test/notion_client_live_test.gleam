//// Live smoke test against the real Notion API. Skipped (returns Ok(Nil))
//// when `NOTION_TOKEN` is unset, so CI without secrets stays green.
////
//// Verifies task 05 done-when: `notion_client.new(token) |> users.me`
//// reaches the API and we can decode the bot user response.

import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/erlang/charlist.{type Charlist}
import gleam/json
import gleam/string
import notion_client
import notion_client/operations

@external(erlang, "os", "getenv")
fn os_getenv(name: Charlist) -> Dynamic

@external(erlang, "erlang", "is_list")
fn is_list(value: Dynamic) -> Bool

@external(erlang, "erlang", "list_to_binary")
fn list_to_binary(list: Dynamic) -> String

fn read_env(name: String) -> Result(String, Nil) {
  let raw = os_getenv(charlist.from_string(name))
  case is_list(raw) {
    True -> Ok(list_to_binary(raw))
    False -> Error(Nil)
  }
}

pub fn users_me_live_test() {
  case read_env("NOTION_TOKEN") {
    Error(_) -> Nil
    Ok(token) -> {
      let client = notion_client.new(token)
      let req =
        operations.retrieve_your_token_sbot_user_request(
          notion_client.base_request(client),
        )
      let assert Ok(resp) = notion_client.send(client, req)
      assert resp.status == 200
      let object_decoder = {
        use object <- decode.field("object", decode.string)
        decode.success(object)
      }
      let assert Ok(object) = json.parse_bits(resp.body, object_decoder)
      assert string.contains(object, "user")
    }
  }
}

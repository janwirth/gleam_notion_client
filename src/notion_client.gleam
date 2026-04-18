//// Notion API client (BEAM only).
////
//// Generated request builders + response decoders live in
//// `notion_client/operations` and `notion_client/schema`.
//// Run `bash scripts/regenerate.sh` to refresh.
////
//// The block below the marker is overwritten by `oas/generator.build`.
//// On BEAM we don't ship the generated facade (it depends on midas /
//// javascript), so `scripts/regenerate.sh` truncates everything below
//// the marker after each run.

import gleam/http
import gleam/http/request

/// Hand-rolled base request used by `notion_client/operations.*_request`.
/// Returns a `Request(BitArray)` rooted at `https://api.notion.com`.
/// Token wiring + auth headers are refined in task 05 (client record).
pub fn base_request(token: String) -> request.Request(BitArray) {
  request.new()
  |> request.set_scheme(http.Https)
  |> request.set_host("api.notion.com")
  |> request.set_body(<<>>)
  |> request.prepend_header("authorization", "Bearer " <> token)
  |> request.prepend_header("notion-version", "2022-06-28")
}
// GENERATED -------------

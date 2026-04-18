//// Shared plumbing for hand-written endpoint facades.
////
//// Each facade builds a request via the generated `operations.*_request`,
//// hands it to `notion_client.request` (which applies retry +
//// classifies non-2xx into `NotionError`), then runs the matching
//// `operations.*_response` decoder. The decoder result is collapsed
//// here so facade modules return a clean `Result(a, NotionError)`.

import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/json
import gleam/result
import gleam/string
import notion_client.{type Client}
import notion_client/error.{type NotionError, ClientError, ResponseBodyError}

pub type ResponseDecoder(a) =
  fn(Response(BitArray)) ->
    Result(Result(a, Response(BitArray)), json.DecodeError)

/// Send `req` through the client's typed transport and decode the
/// response. The decoder's inner `Error(Response)` arm is unreachable
/// here because `notion_client.request` already filters non-2xx, but
/// is mapped to `ResponseBodyError` defensively in case a future
/// change relaxes that filter.
pub fn run(
  client: Client,
  req: Request(BitArray),
  decoder: ResponseDecoder(a),
) -> Result(a, NotionError) {
  use resp <- result.try(notion_client.request(client, req))
  case decoder(resp) {
    Ok(Ok(decoded)) -> Ok(decoded)
    Ok(Error(_)) ->
      Error(
        ClientError(ResponseBodyError(
          "decoder returned non-2xx for 2xx response",
        )),
      )
    Error(err) ->
      Error(
        ClientError(ResponseBodyError("decode failed: " <> string.inspect(err))),
      )
  }
}

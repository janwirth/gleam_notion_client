//// Test-time HTTP sender that caches Notion responses to disk so the
//// rest of the test suite can run without `NOTION_TOKEN`.
////
//// Modes (selected by `NOTION_CACHE_MODE`):
////   * `replay` (default) — read-only; cache miss returns
////     `httpc.FailedToConnect(...)` so the failure is loud.
////   * `record`           — cache hit returns; miss falls through to the
////     live sender and writes the response.
////   * `refresh`          — always live; overwrite the cache file.
////
//// Cache key: `{method}_{sanitized_path}_{sanitized_query}_{sha8(body)}`.
//// Files live at `<root>/<key>.json` with shape
//// `{ status, headers: [{k,v}…], body_b64 }`.

import gleam/bit_array
import gleam/crypto
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/erlang/charlist.{type Charlist}
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/httpc
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import simplifile

pub type Mode {
  Replay
  Record
  Refresh
}

pub type Sender =
  fn(Request(BitArray)) -> Result(Response(BitArray), httpc.HttpError)

pub const default_root: String = "test/cache"

@external(erlang, "os", "getenv")
fn os_getenv(name: Charlist) -> Dynamic

@external(erlang, "erlang", "is_list")
fn is_list(value: Dynamic) -> Bool

@external(erlang, "erlang", "list_to_binary")
fn list_to_binary(value: Dynamic) -> String

pub fn mode_from_env() -> Mode {
  let raw = os_getenv(charlist.from_string("NOTION_CACHE_MODE"))
  case is_list(raw) {
    False -> Replay
    True ->
      case list_to_binary(raw) {
        "record" -> Record
        "refresh" -> Refresh
        _ -> Replay
      }
  }
}

pub fn key(req: Request(BitArray)) -> String {
  let method = method_to_string(req.method)
  let query = case req.query {
    option.Some(q) -> q
    option.None -> ""
  }
  let body_hash =
    crypto.hash(crypto.Sha256, req.body)
    |> bit_array.base16_encode
    |> string.lowercase
    |> string.slice(0, 8)
  method
  <> "_"
  <> sanitize(req.path)
  <> "_"
  <> sanitize(query)
  <> "_"
  <> body_hash
}

pub fn path_for(req: Request(BitArray), root: String) -> String {
  root <> "/" <> key(req) <> ".json"
}

/// Wrap a live sender with caching. Production tests pass
/// `notion_client.send(client, _)` (curried) as `live`.
pub fn wrap(live: Sender, mode: Mode, root: String) -> Sender {
  fn(req) {
    let path = path_for(req, root)
    case mode {
      Refresh -> live_and_write(live, req, path)
      Record ->
        case read_cache(path) {
          Ok(resp) -> Ok(resp)
          Error(_) -> live_and_write(live, req, path)
        }
      Replay ->
        case read_cache(path) {
          Ok(resp) -> Ok(resp)
          Error(_) ->
            Error(httpc.FailedToConnect(
              httpc.Posix("ENOENT:" <> path),
              httpc.Posix("ENOENT:" <> path),
            ))
        }
    }
  }
}

/// Delete a single endpoint's cache file. No-op when absent.
pub fn clear(req: Request(BitArray), root: String) -> Nil {
  let _ = simplifile.delete(path_for(req, root))
  Nil
}

/// Load a cached response by its on-disk path. Used by the decoder
/// test suite to feed cached bodies into generated `*_response`
/// decoders.
pub fn load(path: String) -> Result(Response(BitArray), Nil) {
  read_cache(path)
}

fn live_and_write(
  live: Sender,
  req: Request(BitArray),
  path: String,
) -> Result(Response(BitArray), httpc.HttpError) {
  case live(req) {
    Ok(resp) -> {
      let _ = write_cache(path, resp)
      Ok(resp)
    }
    err -> err
  }
}

fn read_cache(path: String) -> Result(Response(BitArray), Nil) {
  use bytes <- result.try(
    simplifile.read_bits(path) |> result.replace_error(Nil),
  )
  use parsed <- result.try(
    json.parse_bits(bytes, cache_decoder()) |> result.replace_error(Nil),
  )
  let #(status, headers, body) = parsed
  Ok(response.Response(status: status, headers: headers, body: body))
}

fn cache_decoder() -> decode.Decoder(#(Int, List(#(String, String)), BitArray)) {
  let header_decoder = {
    use k <- decode.field("k", decode.string)
    use v <- decode.field("v", decode.string)
    decode.success(#(k, v))
  }
  use status <- decode.field("status", decode.int)
  use headers <- decode.field("headers", decode.list(header_decoder))
  use body_b64 <- decode.field("body_b64", decode.string)
  let body = case bit_array.base64_decode(body_b64) {
    Ok(b) -> b
    Error(_) -> <<>>
  }
  decode.success(#(status, headers, body))
}

fn write_cache(
  path: String,
  resp: Response(BitArray),
) -> Result(Nil, simplifile.FileError) {
  let dir = directory_of(path)
  let _ = simplifile.create_directory_all(dir)
  let body_b64 = bit_array.base64_encode(resp.body, True)
  let doc =
    json.object([
      #("status", json.int(resp.status)),
      #(
        "headers",
        json.array(resp.headers, fn(h) {
          json.object([#("k", json.string(h.0)), #("v", json.string(h.1))])
        }),
      ),
      #("body_b64", json.string(body_b64)),
    ])
  simplifile.write(to: path, contents: json.to_string(doc))
}

fn directory_of(path: String) -> String {
  case list.reverse(string.split(path, "/")) {
    [] -> "."
    [_file, ..rest] -> string.join(list.reverse(rest), "/")
  }
}

fn method_to_string(m: http.Method) -> String {
  case m {
    http.Get -> "get"
    http.Post -> "post"
    http.Put -> "put"
    http.Delete -> "delete"
    http.Patch -> "patch"
    http.Head -> "head"
    http.Options -> "options"
    http.Connect -> "connect"
    http.Trace -> "trace"
    http.Other(s) -> string.lowercase(s)
  }
}

fn sanitize(s: String) -> String {
  string.to_graphemes(s)
  |> list.map(fn(c) {
    case is_safe_char(c) {
      True -> c
      False -> "_"
    }
  })
  |> string.concat
}

fn is_safe_char(c: String) -> Bool {
  case c {
    "a"
    | "b"
    | "c"
    | "d"
    | "e"
    | "f"
    | "g"
    | "h"
    | "i"
    | "j"
    | "k"
    | "l"
    | "m"
    | "n"
    | "o"
    | "p"
    | "q"
    | "r"
    | "s"
    | "t"
    | "u"
    | "v"
    | "w"
    | "x"
    | "y"
    | "z" -> True
    "A"
    | "B"
    | "C"
    | "D"
    | "E"
    | "F"
    | "G"
    | "H"
    | "I"
    | "J"
    | "K"
    | "L"
    | "M"
    | "N"
    | "O"
    | "P"
    | "Q"
    | "R"
    | "S"
    | "T"
    | "U"
    | "V"
    | "W"
    | "X"
    | "Y"
    | "Z" -> True
    "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> True
    "-" | "." -> True
    _ -> False
  }
}

//// Tests for the cached HTTP sender. We don't hit the real Notion
//// API — a fake live sender returns canned responses, the sender
//// writes them to a per-test temp dir, and we assert that subsequent
//// `replay` reads return the same payload without invoking the live
//// sender.

import gleam/dynamic.{type Dynamic}
import gleam/http
import gleam/http/request.{type Request, Request}
import gleam/http/response.{type Response}
import gleam/httpc
import gleam/int
import gleam/option
import gleeunit
import helpers/cached_sender.{Record, Refresh, Replay}
import simplifile

pub fn main() -> Nil {
  gleeunit.main()
}

@external(erlang, "erlang", "put")
fn pdict_put(key: a, value: b) -> Dynamic

@external(erlang, "erlang", "get")
fn pdict_get(key: a) -> Dynamic

@external(erlang, "erlang", "erase")
fn pdict_erase(key: a) -> Dynamic

@external(erlang, "erlang", "unique_integer")
fn unique_integer() -> Int

@external(erlang, "test_helpers", "to_int")
fn unsafe_to_int(d: Dynamic) -> Int

fn install_live_count() -> Nil {
  pdict_put("cs_live_calls", 0)
  Nil
}

fn live_calls() -> Int {
  unsafe_to_int(pdict_get("cs_live_calls"))
}

fn cleanup_counter() -> Nil {
  pdict_erase("cs_live_calls")
  Nil
}

fn fake_live(canned: Response(BitArray)) -> cached_sender.Sender {
  fn(_req) {
    pdict_put("cs_live_calls", live_calls() + 1)
    Ok(canned)
  }
}

fn fake_live_err() -> cached_sender.Sender {
  fn(_req) {
    pdict_put("cs_live_calls", live_calls() + 1)
    Error(httpc.ResponseTimeout)
  }
}

fn make_root() -> String {
  let n = int.absolute_value(unique_integer())
  let root = "test/cache_tmp/run_" <> int.to_string(n)
  let _ = simplifile.create_directory_all(root)
  root
}

fn cleanup_root(root: String) -> Nil {
  let _ = simplifile.delete(root)
  Nil
}

fn sample_request() -> Request(BitArray) {
  request.new()
  |> request.set_method(http.Get)
  |> request.set_path("/v1/users/me")
  |> request.set_body(<<>>)
}

fn sample_response() -> Response(BitArray) {
  response.Response(
    status: 200,
    headers: [#("content-type", "application/json")],
    body: <<"{\"object\":\"user\"}":utf8>>,
  )
}

pub fn replay_miss_returns_failed_to_connect_test() {
  let root = make_root()
  install_live_count()
  let sender = cached_sender.wrap(fake_live(sample_response()), Replay, root)
  let res = sender(sample_request())
  assert live_calls() == 0
  case res {
    Error(httpc.FailedToConnect(_, _)) -> Nil
    _ -> panic as "expected FailedToConnect on replay miss"
  }
  cleanup_counter()
  cleanup_root(root)
}

pub fn record_miss_writes_then_replays_test() {
  let root = make_root()
  install_live_count()

  let recorder = cached_sender.wrap(fake_live(sample_response()), Record, root)
  let assert Ok(resp1) = recorder(sample_request())
  assert resp1 == sample_response()
  assert live_calls() == 1

  // Same key → second call hits cache, no extra live invocation.
  let assert Ok(resp2) = recorder(sample_request())
  assert resp2 == sample_response()
  assert live_calls() == 1

  // A fresh sender in pure Replay mode must read the same file.
  let replayer = cached_sender.wrap(fake_live_err(), Replay, root)
  let assert Ok(resp3) = replayer(sample_request())
  assert resp3 == sample_response()
  assert live_calls() == 1

  cleanup_counter()
  cleanup_root(root)
}

pub fn refresh_overwrites_cache_test() {
  let root = make_root()
  install_live_count()

  let first = response.Response(status: 200, headers: [], body: <<"a":utf8>>)
  let second = response.Response(status: 201, headers: [], body: <<"b":utf8>>)

  let _ = cached_sender.wrap(fake_live(first), Record, root)(sample_request())
  // Refresh should always invoke live, regardless of cache contents.
  let assert Ok(out) =
    cached_sender.wrap(fake_live(second), Refresh, root)(sample_request())
  assert out == second
  assert live_calls() == 2

  // And the replayed cache now reflects `second`.
  let replay = cached_sender.wrap(fake_live_err(), Replay, root)
  let assert Ok(out2) = replay(sample_request())
  assert out2 == second

  cleanup_counter()
  cleanup_root(root)
}

pub fn key_includes_method_path_query_body_test() {
  let req_a =
    request.new()
    |> request.set_method(http.Get)
    |> request.set_path("/v1/databases/abc")
    |> request.set_body(<<>>)
  let req_b =
    request.new()
    |> request.set_method(http.Post)
    |> request.set_path("/v1/databases/abc")
    |> request.set_body(<<>>)
  let req_c = Request(..req_a, query: option.Some("filter=open"))

  assert cached_sender.key(req_a) != cached_sender.key(req_b)
  assert cached_sender.key(req_a) != cached_sender.key(req_c)
}

pub fn clear_removes_single_endpoint_test() {
  let root = make_root()
  install_live_count()

  let _ =
    cached_sender.wrap(fake_live(sample_response()), Record, root)(
      sample_request(),
    )
  cached_sender.clear(sample_request(), root)

  // Replay now misses again because the file was deleted.
  let res = cached_sender.wrap(fake_live_err(), Replay, root)(sample_request())
  case res {
    Error(httpc.FailedToConnect(_, _)) -> Nil
    _ -> panic as "expected miss after clear"
  }

  cleanup_counter()
  cleanup_root(root)
}

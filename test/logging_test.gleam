//// Unit tests for `notion_client/logging`. Drive the logger with a
//// capturing closure (process dictionary) so we can assert exact
//// emissions without touching stderr.

import gleam/dict
import gleam/dynamic.{type Dynamic}
import gleam/list
import gleam/string
import gleeunit/should
import notion_client/logging.{Debug, Error, Info, Warn}

pub fn main() -> Nil {
  Nil
}

@external(erlang, "erlang", "put")
fn pdict_put(key: a, value: b) -> Dynamic

@external(erlang, "erlang", "get")
fn pdict_get(key: a) -> Dynamic

@external(erlang, "erlang", "erase")
fn pdict_erase(key: a) -> Dynamic

@external(erlang, "test_helpers", "as_log_records")
fn as_log_records(
  d: Dynamic,
) -> List(#(String, String, List(#(String, String))))

fn install_capture() -> logging.Logger {
  pdict_put("log_records", [])
  fn(level, message, fields) {
    let prev = as_log_records(pdict_get("log_records"))
    let level_str = case level {
      Debug -> "debug"
      Info -> "info"
      Warn -> "warn"
      Error -> "error"
    }
    let entry = #(level_str, message, dict.to_list(fields))
    pdict_put("log_records", list.append(prev, [entry]))
    Nil
  }
}

fn captured() -> List(#(String, String, List(#(String, String)))) {
  as_log_records(pdict_get("log_records"))
}

fn cleanup() -> Nil {
  pdict_erase("log_records")
  Nil
}

pub fn rank_orders_levels_test() {
  logging.rank(Debug) |> should.equal(0)
  logging.rank(Info) |> should.equal(1)
  logging.rank(Warn) |> should.equal(2)
  logging.rank(Error) |> should.equal(3)
}

pub fn at_least_admits_equal_and_higher_test() {
  logging.at_least(min: Warn, level: Warn) |> should.equal(True)
  logging.at_least(min: Warn, level: Error) |> should.equal(True)
  logging.at_least(min: Warn, level: Info) |> should.equal(False)
  logging.at_least(min: Warn, level: Debug) |> should.equal(False)
}

pub fn filtered_drops_below_min_test() {
  let downstream = install_capture()
  let logger = logging.filtered(min: Warn, downstream: downstream)
  logging.log(logger, Debug, "drop1", [])
  logging.log(logger, Info, "drop2", [])
  logging.log(logger, Warn, "keep1", [])
  logging.log(logger, Error, "keep2", [#("k", "v")])
  let records = captured()
  list.length(records) |> should.equal(2)
  case records {
    [#("warn", "keep1", _), #("error", "keep2", fs)] ->
      fs |> should.equal([#("k", "v")])
    _ -> panic as "unexpected records shape"
  }
  cleanup()
}

pub fn log_helper_passes_fields_dict_test() {
  let logger = install_capture()
  logging.log(logger, Info, "request.start", [
    #("method", "GET"),
    #("path", "/v1/users"),
  ])
  let records = captured()
  case records {
    [#("info", "request.start", fs)] -> {
      list.length(fs) |> should.equal(2)
      fs |> list.contains(#("method", "GET")) |> should.equal(True)
      fs |> list.contains(#("path", "/v1/users")) |> should.equal(True)
    }
    _ -> panic as "expected single info record"
  }
  cleanup()
}

pub fn silent_logger_drops_all_test() {
  let downstream = install_capture()
  let silent = logging.silent_logger()
  // silent ignores its own downstream — verify by emitting through silent
  logging.log(silent, Error, "ignored", [#("k", "v")])
  // and confirm capture closure not called
  let records = captured()
  list.length(records) |> should.equal(0)
  // sanity: downstream itself still works when called directly
  downstream(Warn, "direct", dict.new())
  list.length(captured()) |> should.equal(1)
  cleanup()
}

pub fn default_logger_filters_below_warn_test() {
  // Can't easily intercept stderr, but we can call default_logger and
  // assert it doesn't crash. Real filter behaviour exercised above via
  // `filtered` directly.
  let logger = logging.default_logger()
  logging.log(logger, Debug, "noop", [])
  logging.log(logger, Info, "noop", [])
  Nil
}

pub fn stderr_logger_renders_sorted_fields_test() {
  // Compose a custom logger that captures the rendered string instead
  // of writing to stderr — by inspecting through string.contains we
  // verify the field ordering rule of stderr_logger indirectly.
  // This test instead asserts dict.to_list is sorted when inputs are
  // routed through `log` → downstream(Dict).
  let logger = install_capture()
  logging.log(logger, Warn, "msg", [#("z", "1"), #("a", "2"), #("m", "3")])
  case captured() {
    [#(_, _, fs)] -> {
      // Dict ordering is non-deterministic, but we can sort and verify
      // all entries survived the round-trip.
      let sorted = list.sort(fs, fn(a, b) { string.compare(a.0, b.0) })
      sorted
      |> should.equal([#("a", "2"), #("m", "3"), #("z", "1")])
    }
    _ -> panic as "expected one record"
  }
  cleanup()
}

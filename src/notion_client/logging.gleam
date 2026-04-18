//// Pluggable structured logger for `notion_client`.
////
//// A [`Logger`](#Logger) is `fn(LogLevel, message, fields) -> Nil` —
//// the client emits one call per logical event (request start,
//// response status, retry attempt, request error). Field values are
//// `String` for predictability over the wire; numeric/dynamic data
//// is stringified at the call site.
////
//// Two built-ins:
////   * [`default_logger`](#default_logger) — stderr-backed, filters
////     at `Warn` (the JS SDK default).
////   * [`silent_logger`](#silent_logger) — discards every event.
////
//// Compose your own via [`filtered`](#filtered) +
//// [`stderr_logger`](#stderr_logger), or write a closure that pipes
//// into your favourite log sink (Logstash, Honeycomb, etc.).

import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/string

pub type LogLevel {
  Debug
  Info
  Warn
  Error
}

pub type Logger =
  fn(LogLevel, String, Dict(String, String)) -> Nil

/// Numeric rank for ordering (`Debug` = 0 → `Error` = 3). Used by
/// [`at_least`](#at_least) to decide whether a level passes a filter.
pub fn rank(level: LogLevel) -> Int {
  case level {
    Debug -> 0
    Info -> 1
    Warn -> 2
    Error -> 3
  }
}

/// True when `level` is at least as severe as `min`.
pub fn at_least(min min: LogLevel, level level: LogLevel) -> Bool {
  rank(level) >= rank(min)
}

/// Wrap a downstream logger so events below `min` are dropped before
/// they reach it. Cheap; no allocation on the dropped path.
pub fn filtered(min min: LogLevel, downstream downstream: Logger) -> Logger {
  fn(level, message, fields) {
    case at_least(min, level) {
      True -> downstream(level, message, fields)
      False -> Nil
    }
  }
}

/// Logger that writes one line per event to stderr. Format:
/// `[level] message key=val key=val` (fields sorted by key for
/// deterministic output).
pub fn stderr_logger() -> Logger {
  fn(level, message, fields) {
    let head = "[" <> level_string(level) <> "] " <> message
    let tail = case dict.is_empty(fields) {
      True -> ""
      False -> " " <> render_fields(fields)
    }
    io.println_error(head <> tail)
  }
}

/// Default logger: stderr at `Warn`. Quiet for Debug/Info, prints for
/// Warn/Error.
pub fn default_logger() -> Logger {
  filtered(min: Warn, downstream: stderr_logger())
}

/// Drops every event. Use as the `Client.logger` when you want no
/// logging at all and want the JIT to elide the call sites.
pub fn silent_logger() -> Logger {
  fn(_, _, _) { Nil }
}

/// Convenience helper for call sites: takes a `List(#(k, v))` and
/// converts to a `Dict` before invoking `logger`. Returns `Nil` so it
/// fits naturally as a statement in any block.
pub fn log(
  logger: Logger,
  level: LogLevel,
  message: String,
  fields: List(#(String, String)),
) -> Nil {
  logger(level, message, dict.from_list(fields))
}

fn level_string(level: LogLevel) -> String {
  case level {
    Debug -> "debug"
    Info -> "info"
    Warn -> "warn"
    Error -> "error"
  }
}

fn render_fields(fields: Dict(String, String)) -> String {
  dict.to_list(fields)
  |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
  |> list.map(fn(kv) { kv.0 <> "=" <> kv.1 })
  |> string.join(" ")
}

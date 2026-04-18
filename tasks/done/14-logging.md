# Logging

**Phase:** 7 — Logging
**Depends on:** 05-client-record

## Goal
Pluggable logger matching JS SDK signature.

## Steps
- [x] `src/notion_client/logging.gleam`: `LogLevel = Debug | Info | Warn | Error`
- [x] Logger type: `fn(LogLevel, String, Dict(String, String)) -> Nil`
- [x] Default stderr logger at `Warn` level
- [x] Emit logs at: request start, response status, retry attempt, error

## Done when
Debug mode prints full request/response cycle; default mode quiet unless errors.

## Notes
- `Logger` field type `fn(LogLevel, String, Dict(String, String)) -> Nil`.
  Stringified values (vs `Dynamic`) so the wire shape stays predictable
  and stderr rendering is trivial. Numeric/dynamic fields stringified at
  the call site (`int.to_string`, etc.).
- Built-ins: `default_logger()` (filtered Warn → stderr), `silent_logger()`
  (drops every event), `stderr_logger()` (raw, no filter), `filtered/2`
  (compose your own minimum level).
- `log/4` convenience helper takes `List(#(String, String))` and converts
  to `Dict` so call sites don't import `gleam/dict` just to log.
- `Client` record breaking change: dropped old `log_level: LogLevel`
  (Silent | Info | Debug) + `logger: fn(String) -> Nil` in favour of a
  single `logger: Logger`. `new/1` defaults to `default_logger()`.
- `request/2` emits four events: `request.start` (Debug, method+path),
  `request.retry` (Info, attempt+delay_ms+path), `request.complete`
  (Debug, path+status), `request.error` (Warn, path+error label).
- Retry observer: `retry.run/6` gained an `on_retry: Observer` parameter
  (`fn(attempt, delay_ms) -> Nil`) wired through to the new
  `request.retry` event. Tests pass `fn(_, _) { Nil }`.
- stderr renders `[level] message key=val key=val` with fields sorted by
  key for deterministic output.
- Tests (7 new): rank ordering, `at_least` boundary, `filtered` drop
  semantics, `log/4` field round-trip, `silent_logger` no-op,
  `default_logger` smoke (no stderr capture), field key ordering. Drives
  capture via process dictionary; new `as_log_records/1` cast helper in
  `test_helpers.erl`.

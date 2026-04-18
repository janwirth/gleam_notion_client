# Logging

**Phase:** 7 — Logging
**Depends on:** 05-client-record

## Goal
Pluggable logger matching JS SDK signature.

## Steps
- [ ] `src/notion_client/logging.gleam`: `LogLevel = Debug | Info | Warn | Error`
- [ ] Logger type: `fn(LogLevel, String, Dict(String, Dynamic)) -> Nil`
- [ ] Default stderr logger at `Warn` level
- [ ] Emit logs at: request start, response status, retry attempt, error

## Done when
Debug mode prints full request/response cycle; default mode quiet unless errors.

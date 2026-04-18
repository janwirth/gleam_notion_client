# Retry with backoff

**Phase:** 3 — Retries
**Depends on:** 06-errors

## Goal
Automatic retries matching JS SDK policy.

## Steps
- [x] `src/notion_client/retry.gleam`: exponential backoff + jitter
- [x] Retry 429 on all methods; 500/503 on GET/DELETE only
- [x] Honor `Retry-After` header when present
- [x] `retry: NoRetry` opt-out on Client config
- [x] Max retry count config (`Backoff(max_attempts, base_delay_ms, max_delay_ms)`)
- [x] Unit tests with fake sender + fake clock

## Done when
Retry tests pass; 429 responses trigger backoff and eventual success.

## Notes
- Pure module: `retry.run` takes `Sender`, `Sleeper`, `Jitter` callbacks so
  tests drive it deterministically. Production uses
  `process.sleep` + `int.random` injected by `notion_client.request`.
- Retry classification matches JS SDK: 429 always; 500/503 only on GET and
  DELETE (idempotent verbs). Transport `httpc.ResponseTimeout` also retried;
  `FailedToConnect` and `InvalidUtf8Response` are not (likely terminal).
- Backoff: `min(base * 2^attempt, max) + jitter(capped)`. `Retry-After`
  header (seconds) overrides the computed delay for that attempt.
- New `Client.retry` field is `RetryConfig` (replaces old `Retry` type).
  Default constructor `default_retry = Backoff(3, 250, 5000)` matches the
  JS SDK defaults closely. Pass `NoRetry` to disable.
- Tests use the Erlang process dictionary for the fake sender's response
  queue and a tiny `test/test_helpers.erl` shim for `Dynamic` casts. Seven
  cases cover NoRetry, 429 success, idempotent-only 500, Retry-After,
  exhaustion, transport timeout, and backoff capping.

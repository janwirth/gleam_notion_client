# Retry with backoff

**Phase:** 3 — Retries
**Depends on:** 06-errors

## Goal
Automatic retries matching JS SDK policy.

## Steps
- [ ] `src/notion_client/retry.gleam`: exponential backoff + jitter
- [ ] Retry 429 on all methods; 500/503 on GET/DELETE only
- [ ] Honor `Retry-After` header when present
- [ ] `retry: False` opt-out on Client config
- [ ] Max retry count config
- [ ] Unit tests with fake sender + fake clock

## Done when
Retry tests pass; 429 responses trigger backoff and eventual success.

# Cached HTTP sender for tests

**Phase:** 8 — Response Cache
**Depends on:** 05-client-record

## Goal
Test-time sender that caches responses to `test/cache/` — one file per request.

## Steps
- [ ] `test/helpers/cached_sender.gleam`
- [ ] Key function: `{method, path, sorted_query, body_sha}` → sanitized filepath under `test/cache/<module>/<op>__<params>.json`
- [ ] Cache hit → read file → return
- [ ] Cache miss → live call → write file (`{status, headers, body}`) → return
- [ ] Env `NOTION_CACHE_MODE`:
  - `replay` (default): cache-only, miss = error
  - `record`: miss = live + write
  - `refresh`: always live, overwrite
- [ ] Helper to clear a single endpoint's cache

## Done when
With `NOTION_CACHE_MODE=record` and valid token, tests populate `test/cache/`; subsequent `replay` runs pass without token.

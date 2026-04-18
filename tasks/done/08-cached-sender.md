# Cached HTTP sender for tests

**Phase:** 8 — Response Cache
**Depends on:** 05-client-record

## Goal
Test-time sender that caches responses to `test/cache/` — one file per request.

## Steps
- [x] `test/helpers/cached_sender.gleam`
- [x] Key function: `{method, path, query, sha8(body)}` → sanitized
      filepath `<root>/<key>.json` (default root `test/cache/`)
- [x] Cache hit → read file → return
- [x] Cache miss → live call → write file (`{status, headers, body_b64}`) → return
- [x] Env `NOTION_CACHE_MODE`:
  - `replay` (default): cache-only, miss = `httpc.FailedToConnect(ENOENT)`
  - `record`: miss = live + write
  - `refresh`: always live, overwrite
- [x] Helper to clear a single endpoint's cache (`cached_sender.clear/2`)

## Done when
With `NOTION_CACHE_MODE=record` and valid token, tests populate `test/cache/`;
subsequent `replay` runs pass without token.

## Notes
- `wrap(live, mode, root) -> Sender` has the same signature as
  `notion_client.send` partially applied — real callers use
  `cached_sender.wrap(fn(r) { notion_client.send(c, r) }, mode, root)`.
- Cache file shape is JSON `{status: Int, headers: [{k,v}…], body_b64: String}`.
  Body base64-encoded so binary responses round-trip cleanly.
- Replay miss returns `httpc.FailedToConnect(Posix("ENOENT:<path>"), …)` —
  surfaces the missing key clearly in test output without inventing a
  whole new error variant.
- Tests use a per-test `test/cache_tmp/run_<unique>` root via
  `erlang:unique_integer()` so they never collide with each other or
  the real `test/cache/` directory; recursive `simplifile.delete`
  tears down at the end of each test.
- Added dev deps: `simplifile`, `gleam_crypto`, `filepath`. Already
  present transitively via `oas_generator`; promoted to direct deps so
  the helper isn't fragile to upstream changes.
- `.gitignore` now ignores `test/cache_tmp/` so leftover test artifacts
  don't leak into commits.
- Live seeding against Notion is task 09; this task only covers the
  mechanism + unit-level behaviour.

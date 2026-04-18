# Decoder test suite

**Phase:** 9 — Decoder Tests
**Depends on:** 09-seed-cache

## Goal
Every cached response decodes without error; every item in list responses decodes.

## Steps
- [x] `test/decoders_test.gleam`
- [x] For each cached file: load → decode with endpoint's response decoder → assert `Ok`
- [x] For list responses: iterate `results` array (search spot-check)
- [x] On failure: print raw JSON path + decoder error for easy fix
- [ ] Round-trip test: decode → encode → decode → assert equal — skipped; generated decoders only, no encoders yet
- [x] Run in CI (no token needed, replay mode is default)

## Done when
Full test suite green against all cached responses; adding a new cache file automatically gets decoded.

## Notes
- `replay_all_cached_test` walks `test/cache/*.json`, classifies each filename to an endpoint slug, dispatches to the generated `*_response` decoder.
- Per-file shape: 2xx → `Ok(Ok(_))`; non-2xx → `Ok(Error(Response))` (the cached 403 from comments.list passes this way).
- Adding a new endpoint cache: add a branch to `dispatch/2` mapping the slug to the decoder; `classify/1` already covers the pattern families. Unknown slugs panic with the offending filename.
- `cached_sender.load/1` made public so the decoder suite can read cache files without going through the sender wrapper.
- 20 tests pass (was 17 before this task: 7 retry + 5 cached_sender + 5 client/error/seed). Two new top-level tests added here plus the dispatch loop.
- Round-trip test deferred: generated module exposes `*_response` decoders but no symmetric encoders, so encode→decode equality is not expressible without hand-rolling.
- `endpoint_for_filename` uses `use <- match(condition, slug)` callback chain because Gleam clause guards cannot call functions (`string.starts_with`/`string.contains` both fail in `if` guards).

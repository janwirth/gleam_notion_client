# Decoder test suite

**Phase:** 9 — Decoder Tests
**Depends on:** 09-seed-cache

## Goal
Every cached response decodes without error; every item in list responses decodes.

## Steps
- [ ] `test/decoders_test.gleam`
- [ ] For each cached file: load → decode with endpoint's response decoder → assert `Ok`
- [ ] For list responses: iterate `results` array, run item decoder per item, assert all `Ok`
- [ ] On failure: print raw JSON + decoder error path for easy fix
- [ ] Round-trip test: decode → encode → decode → assert equal
- [ ] Run in CI (no token needed, replay mode)

## Done when
Full test suite green against all cached responses; adding a new cache file automatically gets decoded.

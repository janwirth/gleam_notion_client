# Cleanup one-shot — wipe existing duplicate rows

**Phase:** v3 / 5 of 5
**Depends on:** 26-fixtures-module
**Spec:** `specs/v3-property-types.md` §"Test hygiene — dedup guard"

## Goal
Run `fixtures.archive_all_rows` once against the reference DB to clear
the duplicate pages accumulated across all prior `record`-mode runs.
Commit no caches for this — it's a one-off state mutation, not a
repeatable test.

## Steps
- [ ] Add `test/cleanup_live_test.gleam` containing a single test that
      invokes `fixtures.archive_all_rows` when `NOTION_TOKEN`,
      `NOTION_BOOTSTRAP_DATABASE_ID`, and
      `NOTION_ALLOW_DB_WIPE=1` are all set. Guards ensure the suite
      never wipes by accident.
- [ ] Run once:
      `NOTION_CACHE_MODE=record NOTION_ALLOW_DB_WIPE=1 \
        gleam test -- --only cleanup_db_live` (or equivalent test
      filter). Verify empty DB via
      `notion_client/databases.query` with no filter.
- [ ] Record the archive count in this task file.
- [ ] Delete any stale cache files under `test/cache/` that point at
      archived page IDs (their content decoders would still pass, but
      they're noise).
- [ ] Leave `test/cleanup_live_test.gleam` in the tree so it can be
      re-invoked on demand. Do **not** commit the cache fixtures from
      this run (destructive — must always be live).

## Done when
- Reference DB contains 0 non-archived pages.
- Follow-up `NOTION_CACHE_MODE=record gleam test` creates exactly the
  set of rows expected by task 28 + 29 (one per live test).

## Notes
- `NOTION_ALLOW_DB_WIPE` is a belt-and-braces guard: archive_all_rows
  is destructive, so we don't want a casual `gleam test` to trigger
  it. Ralph sets the env var explicitly when running this task.
- Notion's "archive" is soft-delete — content stays recoverable for 30
  days. If a run goes wrong it can be undone by hand.

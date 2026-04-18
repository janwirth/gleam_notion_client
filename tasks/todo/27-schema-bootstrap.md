# Schema bootstrap — ensure canonical property schema on ref DB

**Phase:** v3 / 2 of 5
**Depends on:** 26-fixtures-module
**Spec:** `specs/v3-property-types.md` §"Canonical schema"

## Goal
Implement `fixtures.ensure_schema(client, db_id)` so the reference DB has
every property type the matrix test expects.

## Steps
- [ ] PATCH /v1/databases/<id> with full property map from spec §schema
      table. Editable: rich_text, number (format number), select
      (draft/review/done), status (default options), multi_select
      (alpha/beta/gamma), date, checkbox, url, email, phone_number, files.
      Read-only additions: unique_id (prefix NC), formula (expression
      `length(prop("Text"))`).
- [ ] Idempotent: re-invoking against an already-populated DB must return
      200 without altering values. Notion merges on name match, so
      passing the same body twice is safe.
- [ ] Runs once per OS process: guard via persistent_term or ETS table
      (`ensure_schema_once`). Any `fixtures.*` call that depends on
      schema presence triggers it lazily.
- [ ] Skip entirely in `replay` mode.
- [ ] Commit `test/cache/patch__v1_databases_<id>_*.json` for replay
      coverage of the PATCH response shape.

## Done when
- `NOTION_CACHE_MODE=record gleam test -- --only rich_text_round_trip_live`
  ensures schema and no subsequent test needs manual DB prep.
- Running twice back-to-back issues a second PATCH that succeeds with
  no user-visible change.

## Notes
- Reference for schema syntax: https://developers.notion.com/reference/update-a-database.
- `created_time`, `last_edited_time`, `created_by`, `last_edited_by` are
  *always* present — no PATCH required; the matrix test just asserts on
  them.

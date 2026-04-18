# v3 — Property-type coverage + test hygiene

## Problem

1. The reference database (`NOTION_BOOTSTRAP_DATABASE_ID`) currently has only
   the default `Name` title column. Every property type supported by
   `src/notion_client/properties.gleam` and `specs/v2-markdown-extensions.md`
   §8 therefore lacks a live round-trip: the YAML frontmatter emitter and
   inverse PATCH builder have unit coverage, not integration coverage.
2. Each `*_live_test.gleam` unconditionally `pages.create`s a new row per
   run. When tests replay in `record` / `refresh` mode, the DB accumulates
   duplicate "phase-N ⟨name⟩" pages. After ~20 runs the DB is cluttered
   with archives masquerading as live rows.

This spec closes both gaps so property-type behaviour is exercised end-to-end
**and** the DB state stays idempotent across runs.

## Goals

- Reference DB owns a canonical property schema covering every editable +
  read-only type exposed in v2 §8. Bootstrapped automatically, not by hand.
- Test runs are idempotent: at most one live row per test title exists
  after the suite, regardless of how many times it ran.
- A new live matrix test exercises frontmatter ↔ Notion for every editable
  type and asserts read-only types appear under `properties_readonly` with
  `--full-properties`.

## Non-goals

- Cross-database properties (`relation`, `rollup`, `people`) stay out of
  v3. They need a second DB or real user IDs; track separately.
- Notion UI / Markdown ergonomics changes. Emitter/parser contracts from
  v2 §8 are unchanged; v3 only adds integration coverage.

## Canonical schema

`PATCH /v1/databases/<db_id>` is issued once per suite to converge the
schema. Existing matching columns are no-ops; missing columns are added.

Editable columns (all exercised by matrix test):

| YAML key       | Notion type    | Config                                         |
|----------------|----------------|------------------------------------------------|
| `Name`         | `title`        | pre-existing                                   |
| `Text`         | `rich_text`    | —                                              |
| `Count`        | `number`       | `format: number`                               |
| `Stage`        | `select`       | options: `draft`, `review`, `done`             |
| `State`        | `status`       | default options (`Not started`/`In progress`/`Done`) |
| `Tags`         | `multi_select` | options: `alpha`, `beta`, `gamma`              |
| `Due`          | `date`         | —                                              |
| `Done`         | `checkbox`     | —                                              |
| `Link`         | `url`          | —                                              |
| `Mail`         | `email`        | —                                              |
| `Phone`        | `phone_number` | —                                              |
| `Files`        | `files`        | external URLs only (no file uploads)           |

Read-only columns (matrix test asserts they surface under
`properties_readonly` with `full: True`):

| YAML key       | Notion type        | Notes                                     |
|----------------|--------------------|-------------------------------------------|
| `Ticket`       | `unique_id`        | prefix `NC`                               |
| `Created`      | `created_time`     | auto                                      |
| `Edited`       | `last_edited_time` | auto                                      |
| `Creator`      | `created_by`       | auto                                      |
| `Editor`       | `last_edited_by`   | auto                                      |
| `Words`        | `formula`          | expression: `length(prop("Text"))`        |

## Test hygiene — dedup guard

New helper module `test/helpers/fixtures.gleam`:

```gleam
pub fn ensure_schema(client, db_id) -> Nil
pub fn archive_all_rows(client, db_id) -> Nil
pub fn archive_by_title(client, db_id, title: String) -> Nil
pub fn create_row(client, db_id, title: String, extra_properties: Json) -> String
```

- `ensure_schema` — idempotent. PATCHes DB with the full property map.
  Skipped when `NOTION_CACHE_MODE=replay` (read-only). Run once per
  process behind a persistent-term guard (`ensure_schema_once`).
- `archive_all_rows` — queries DB, archives every non-archived page.
  **Called once** at suite init in `record` / `refresh` modes only.
  A one-shot `test/cleanup_live_test.gleam` runs this as its sole test
  to give us a deliberate "wipe the DB" entry-point.
- `archive_by_title` — queries DB for pages whose title equals `title`
  exactly and archives them. Called at the **start** of each live
  round-trip, replacing each test's ad-hoc `create_row` call.
- `create_row` — wraps the deterministic title pattern, property
  payload construction, and response parsing that each live test
  currently duplicates. All existing `create_row` helpers in
  `test/*_live_test.gleam` migrate to this.

Archive API: `PATCH /v1/pages/<id>` with body `{ "archived": true }`.

Title query: `POST /v1/databases/<id>/query` with
`{ "filter": { "property": "Name", "title": { "equals": <title> } } }`.

## Matrix test

New `test/properties_live_test.gleam`:

1. `ensure_schema` — ensure the canonical schema is live.
2. `archive_by_title(..., "v3 property matrix")`.
3. `create_row` with a full property payload exercising every editable
   type with a distinct, reproducible value.
4. `GET /v1/pages/<id>`; run `properties.render_frontmatter(page, True)`.
5. Parse rendered YAML via `notion_client/yaml`. Assert each editable key
   round-trips to the original value (scalar equality; lists by set).
6. Assert `properties_readonly:` section contains `Ticket`, `Created`,
   `Edited`, `Creator`, `Editor`, `Words` and each has a non-null value.
7. Reverse direction: take the rendered YAML, run
   `properties.build_patch(page, yaml)`, `PATCH /v1/pages/<id>` with it,
   then refetch and assert editable values unchanged (confirms emitter
   and builder are symmetric).

Skipped with `Nil` when `NOTION_TOKEN` or `NOTION_BOOTSTRAP_DATABASE_ID`
are unset (matches v2 convention).

## Kanban tasks

| # | Title                             | Depends on |
|---|-----------------------------------|------------|
| 26 | fixtures-module                  | —          |
| 27 | schema-bootstrap                 | 26         |
| 28 | dedup-guard-migration            | 26         |
| 29 | property-matrix-live             | 26, 27, 28 |
| 30 | cleanup-one-shot                 | 26         |

## Acceptance

- `gleam test` passes in `replay` mode with no live credentials.
- `NOTION_CACHE_MODE=record gleam test` ends with **one** row per live
  test in the reference DB (0 duplicates).
- `properties_live_test` round-trips all 12 editable property types and
  confirms all 6 read-only types appear under `properties_readonly`.
- Re-running `gleam test` in record mode a second time produces **no
  new rows** (every create is preceded by an archive-by-title).

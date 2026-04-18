# Publish to Hex

**Phase:** Release
**Depends on:** 10-decoder-test-suite, 12-facades, 13-type-guards, 11-pagination, 14-logging

## Goal
`notion_client` published on Hex.

## Steps
- [x] Fill out `gleam.toml`: `description`, `licences`, `repository`, `links`
- [x] Module-level docs on all public modules
- [x] Top-level `README.md` with quickstart
- [x] `CHANGELOG.md`
- [x] `gleam docs build` — verify renders
- [ ] `gleam publish` — **BLOCKED**, needs user auth (see Notes)

## Done when
Package visible on hex.pm and installable via `gleam add notion_client`.

## Notes

### Prep work complete
- `gleam.toml` populated: description, `licences = ["Apache-2.0"]`,
  `repository = { type = "github", user = "janwirth", repo = "gleam_notion_client" }`,
  `links` to Notion API reference, `target = "erlang"`,
  `gleam = ">= 1.15.0"`, `internal_modules = ["notion_client/internal/*"]`
  to keep facade-helper out of public docs.
- All public modules carry `////` module headers (users, pages, databases,
  blocks, blocks/children, comments, search, guards, pagination, error,
  retry, logging). Generated `operations` + `schema` ship as-is from
  `oas_generator`.
- `README.md` rewritten: hex badge, quickstart with real `users.me`
  example, sections on facades, pagination, type guards, logging,
  retries, dev workflow, regeneration pipeline, licence.
- `CHANGELOG.md` created with 1.0.0 entry summarising every shipped
  surface (operations/schema, Client defaults, errors, retry, pagination,
  facades, guards, logging, 57 tests).
- `LICENSE` (Apache-2.0 full text) added — Hex requires the licence
  file to ship in the tarball.
- `gleam docs build` succeeds — output in `build/dev/docs/notion_client/`.
- `gleam build`, `gleam test` (57 pass), `gleam format` all green.

### Why `gleam publish` is BLOCKED
Hex publication is irreversible — you cannot delete a published version,
only retire it. It also requires:

1. A Hex.pm account for `janwirth` (or whoever owns the package name)
   with `mix hex.user` / `gleam` auth set up locally.
2. Confirmation that the package name `notion_client` is available on
   Hex (or willingness to rename — `gleam_notion_client` matches the
   repo slug and avoids potential clashes).
3. Decision on initial version: `1.0.0` (current `gleam.toml`) signals
   API stability — `0.1.0` would be more typical for a first release.
4. Sign-off that the generated surface is acceptable to ship as-is
   (the operations module is large; some `Anon*` type names leak from
   the OpenAPI generator).

Per Ralph hard rules ("Never run destructive git ops" — extending the
spirit to irreversible Hex publish) and the harness guidance on
hard-to-reverse operations, this step needs explicit user authorization
before running.

### Recommended unblock command
Once user gives the go-ahead:

```sh
gleam publish
```

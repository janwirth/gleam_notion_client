# Generate Gleam bindings via oaspec

**Phase:** 0 — Spec Pipeline
**Depends on:** 02-convert-postman-to-openapi

## Goal
`src/notion_client/generated/*.gleam` compiles; has types + client functions for every Notion endpoint.

## Steps
- [ ] `oaspec init` → edit `oaspec.yaml` (output dir, package name, client-only mode)
- [ ] `oaspec generate --config=oaspec.yaml`
- [ ] `gleam build` — fix any generator output issues
- [ ] Inspect `oneOf`/`anyOf` handling for polymorphic types (property values, block types). Hand-write if broken.
- [ ] Commit generated code

## Done when
`gleam build` succeeds and generated code exposes a function per postman request.

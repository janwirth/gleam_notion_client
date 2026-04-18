# Hand-written endpoint facades

**Phase:** 4 — Endpoints
**Depends on:** 03-generate-gleam-from-openapi, 05-client-record, 06-errors

## Goal
Ergonomic Gleam modules over generated code — mirrors JS SDK namespaces.

## Steps
- [x] `notion_client/users` — `list`, `retrieve`, `me`
- [ ] `notion_client/data_sources` — `query`, `retrieve`, `create`, `update` — SKIPPED (not in generated module; see Notes)
- [x] `notion_client/databases` — `query`, `retrieve`, `create`, `update`
- [x] `notion_client/pages` — `create`, `retrieve`, `update`, `properties_retrieve`
- [x] `notion_client/blocks` — `retrieve`, `update`, `delete`
- [x] `notion_client/blocks/children` — `list`, `append`
- [x] `notion_client/comments` — `create`, `list`
- [x] `notion_client/search`
- [ ] `notion_client/views` — `create` — SKIPPED (not in generated module; see Notes)
- [ ] `notion_client/oauth` — `token`, `revoke`, `introspect` — SKIPPED (not in generated module; see Notes)

Each facade: thin wrapper calling generated fn + passing Client config.

## Done when
All modules compile, each has at least one passing cached test.

## Notes
- Shared plumbing in `src/notion_client/internal/facade.gleam`: `run(client, req, decoder) -> Result(a, NotionError)`. Calls `notion_client.request` (which already applies retry + classifies non-2xx into `NotionError`) then collapses the generated decoder's nested `Result(Result(_, Response), DecodeError)` into a flat `Result(_, NotionError)`. Inner `Error(Response)` arm is unreachable in practice but mapped to `ResponseBodyError` defensively.
- Skipped modules (`data_sources`, `views`, `oauth`) are not in `operations.gleam` because the source Postman collection only documents the v1 REST surface. To add them, regenerate from a Notion OpenAPI spec that includes those endpoints (or hand-write the requests against the live Notion docs) and uncomment the corresponding step here.
- `comments.list` and `blocks/children.list` take `page_size: Option(String)` rather than `Option(Int)` because the generated request builders pass query values straight into `utils.set_query` which expects strings.
- Facade tests (`test/facades_test.gleam`): each facade with a cached fixture asserts the request key matches the cached file (so production `Replay` mode would hit) and the decoder produces the typed variant. `facade_refs_compile_test` references every public facade function so accidental removal is a build break. 8 facade tests added; suite now at 39 passing.

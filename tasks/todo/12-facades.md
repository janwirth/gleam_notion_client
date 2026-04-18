# Hand-written endpoint facades

**Phase:** 4 — Endpoints
**Depends on:** 03-generate-gleam-from-openapi, 05-client-record, 06-errors

## Goal
Ergonomic Gleam modules over generated code — mirrors JS SDK namespaces.

## Steps
- [ ] `notion_client/users` — `list`, `retrieve`, `me`
- [ ] `notion_client/data_sources` — `query`, `retrieve`, `create`, `update`
- [ ] `notion_client/databases` — `query`, `retrieve`, `create`, `update`
- [ ] `notion_client/pages` — `create`, `retrieve`, `update`, `properties_retrieve`
- [ ] `notion_client/blocks` — `retrieve`, `update`, `delete`
- [ ] `notion_client/blocks/children` — `list`, `append`
- [ ] `notion_client/comments` — `create`, `list`
- [ ] `notion_client/search`
- [ ] `notion_client/views` — `create`
- [ ] `notion_client/oauth` — `token`, `revoke`, `introspect`

Each facade: thin wrapper calling generated fn + passing Client config.

## Done when
All modules compile, each has at least one passing cached test.

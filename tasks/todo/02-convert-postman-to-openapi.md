# Convert Postman collection to OpenAPI

**Phase:** 0 — Spec Pipeline
**Depends on:** 01-install-toolchain

## Goal
`openapi.json` committed, lint-clean enough for oaspec to consume.

## Steps
- [ ] `postman2openapi "Notion API.postman_collection.json" -f json > openapi.json`
- [ ] Run OpenAPI linter (spectral or similar); list errors
- [ ] Hand-fix lint errors (expect 30–60 min — tools unmaintained, common issue: `nullable: true` without type)
- [ ] Verify `openapi.json` validates as OpenAPI 3.x
- [ ] Commit `openapi.json`

## Done when
`openapi.json` validates and every Notion endpoint in the postman collection has a corresponding path.

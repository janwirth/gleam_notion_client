# Convert Postman collection to OpenAPI

**Phase:** 0 — Spec Pipeline
**Depends on:** 01-install-toolchain

## Goal
`openapi.json` committed, lint-clean enough for oaspec to consume.

## Steps
- [x] `postman2openapi "Notion API.postman_collection.json" -f json > openapi.json`
- [x] Run OpenAPI linter (spectral or similar); list errors
- [x] Hand-fix lint errors (expect 30–60 min — tools unmaintained, common issue: `nullable: true` without type)
- [x] Verify `openapi.json` validates as OpenAPI 3.x
- [x] Commit `openapi.json`

## Done when
`openapi.json` validates and every Notion endpoint in the postman collection has a corresponding path.

## Notes
- `postman2openapi` v1.2.1 CLI is `postman2openapi <file> -f json` (positional input, `-f` = output format). The original task command (`-f` for input) was wrong for this version; corrected.
- Fix script `scripts/fix_openapi.mjs` handles the two systematic spectral errors:
  - 49 instances of `{nullable: true, example: null}` without a `type` — defaulted to `string` (or to the inferred type of `example` when non-null).
  - 20 instances of `text.link` properties — schema declared `nullable: true` but example payloads sometimes contain `{url: "..."}`. Rewrote those schemas to `{type: "object", nullable: true, properties: {url: {type: string}}}`.
  - 2 trailing-slash paths (`/v1/databases/`, `/v1/pages/`) stripped to satisfy the `path-keys-no-trailing-slash` warning.
- Linter: `npx @stoplight/spectral-cli` with `extends: ["spectral:oas"]` ruleset (`.spectral.yaml`). Final lint exits with **0 errors, 0 warnings**.
- `regenerate.sh` updated: postman2openapi → fix_openapi.mjs → spectral lint, all wired and verified end-to-end.
- 19 ops emitted, covering every unique postman endpoint (postman has 25 items but several are duplicate examples for the same route).
- Endpoints: GET/POST/PATCH/DELETE on `/v1/{users,databases,pages,blocks,comments,search}` plus block-children, database-query, page-property, users-me.

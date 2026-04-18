# Regeneration script + CI drift check

**Phase:** 0 — Spec Pipeline
**Depends on:** 03-generate-gleam-from-openapi

## Goal
One command regenerates spec + Gleam code. CI fails if committed output drifts.

## Steps
- [x] `scripts/regenerate.sh`: postman → openapi → oaspec generate
- [x] Add `oaspec generate --check` CI step
- [x] Document in `README.md` how to regenerate

## Done when
`bash scripts/regenerate.sh` produces no diff on clean tree.

## Notes
- `scripts/regenerate.sh` was scaffolded in tasks 01–03; this task hardens it. Final pipeline:
  1. `postman2openapi`
  2. `node scripts/fix_openapi.mjs` (nullable-without-type, trailing slash, text.link)
  3. `npx @stoplight/spectral-cli lint`
  4. truncate prior facade in `src/notion_client.gleam`
  5. `gleam run -m notion_client/dev` (oas_generator)
  6. truncate freshly spliced midas/JS facade
  7. patch `oas/generator/utils` → `notion_client/internal/utils`
  8. `node scripts/dedupe_anons.mjs`
  9. `gleam format` *(added in this task — generator emits non-canonical import order; without this, regen drifts every run)*
  10. `gleam build`
- Verified determinism by running `regenerate.sh` twice on a clean tree and diffing — outputs identical, no drift.
- `oaspec generate --check` does not exist (oas_generator has no CLI). Equivalent CI check implemented in `.github/workflows/regenerate-check.yml`: checkout → install postman2openapi + gleam + node → run `scripts/regenerate.sh` → `git diff --quiet -- openapi.json src/notion_client` → fail with the drift diff if non-empty.
- README "Regenerating the SDK" section added with toolchain prerequisites and a one-line summary of what the script does.
- Tested drift check locally: `bash scripts/regenerate.sh && git diff --quiet -- openapi.json src/notion_client` exits 0 ("OK: no drift").

# Generate Gleam bindings via oaspec

**Phase:** 0 — Spec Pipeline
**Depends on:** 02-convert-postman-to-openapi

## Goal
`src/notion_client/generated/*.gleam` compiles; has types + client functions for every Notion endpoint.

## Steps
- [x] `oaspec init` → edit `oaspec.yaml` (output dir, package name, client-only mode)
- [x] `oaspec generate --config=oaspec.yaml`
- [x] `gleam build` — fix any generator output issues
- [x] Inspect `oneOf`/`anyOf` handling for polymorphic types (property values, block types). Hand-write if broken.
- [x] Commit generated code

## Done when
`gleam build` succeeds and generated code exposes a function per postman request.

## Notes
- `oaspec` does not exist (see task 01). Substituted **CrowdHailer/oas_generator** v2.3.1 (Hex package, no CLI). Invocation is a Gleam dev module: `test/notion_client/dev.gleam` calls `oas/generator.build("./openapi.json", ".", "notion_client", [])` and is run with `gleam run -m notion_client/dev`.
- Generator layout is fixed by upstream: writes `src/notion_client/operations.gleam`, `src/notion_client/schema.gleam`, and splices a facade into `src/notion_client.gleam` after a `// GENERATED ---` marker. Action plan said `src/notion_client/generated/*.gleam`; deviation documented here.
- **`oas_generator_utils` is `target = "javascript"`** (uses `gleam/javascript/array` + ffi.mjs for `merge`). Mandate is BEAM-only. Vendored a BEAM-compatible reimplementation as `src/notion_client/internal/utils.gleam`. Generated code's `import oas/generator/utils` is post-processed to `import notion_client/internal/utils` by `scripts/regenerate.sh`. `merge` panics on call (not used; spec has zero `allOf`).
- Generator's spliced top-level facade uses **midas** (`t.fetch`/`t.do`/`t.try`/`t.done`) and `handle_errors`. midas is also JS-target and not in deps. Per upstream README ("If you do not want to use Midas you can delete the top project file and use the functions in `operations.gleam` directly"), `scripts/regenerate.sh` truncates everything below the `// GENERATED ---` marker after each run. Hand-written facade lands in later tasks (12 — facades).
- **Bug in upstream generator**: it emits the *same* `pub type AnonXX` and `pub fn anon_xx_decoder/encode` definitions multiple times when the same hashed inline schema appears in multiple operations. Compile fails with "Duplicate type/definition". Worked around with `scripts/dedupe_anons.mjs` — keeps first occurrence by name (the hash is content-derived so all duplicates have identical bodies). Reduces operations.gleam from ~12130 → ~5174 lines.
- No `oneOf`/`anyOf` in `openapi.json` (postman2openapi flattens). No polymorphic decoder hand-writing needed in this task; that work shifts to whenever a more complete spec is adopted (e.g. property values, block types).
- Spec has 19 unique endpoints. Generated `operations.gleam` exposes 19 `*_request` + 19 `*_response` functions covering every postman item.
- Direct deps added: `gleam_http`, `gleam_json`, `snag` (silenced transitive-dep warnings). `oas_generator_utils` left as a runtime dep but not imported by our code; transitive `gleam_javascript` does not get compiled on Erlang target.
- `regenerate.sh` final pipeline: postman2openapi → fix_openapi → spectral lint → truncate-entry → `gleam run -m notion_client/dev` → truncate-entry → patch-utils-import → dedupe-anons → `gleam build`.
- `gleam build` + `gleam test` both succeed (1 placeholder test passing). Warnings remaining are unused imports in generated code (`gleam/float`, `gleam/int`, `notion_client/schema`, plus `gleam/dict|json|dynamic|decode` in the empty `schema.gleam`); harmless, will clear up as schemas/types get used.

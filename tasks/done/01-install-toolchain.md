# Install spec-pipeline toolchain

**Phase:** 0 — Spec Pipeline
**Depends on:** none

## Goal
`postman2openapi` and `oaspec` available on PATH.

## Steps
- [x] Install Rust toolchain if missing
- [x] `cargo install postman2openapi-cli`
- [x] Install `oaspec` (pin version; check [oaspec releases](https://github.com/) for install method)
- [x] Document exact versions in `scripts/regenerate.sh` header

## Done when
`postman2openapi --version` and `oaspec --version` both succeed.

## Notes
- Rust 1.92.0 + cargo present at `/home/dev/.cargo/bin`.
- `postman2openapi` v1.2.1-dev already installed at `/home/dev/.cargo/bin/postman2openapi`. Verified `postman2openapi --version` works.
- **`oaspec` does not exist** as a Gleam codegen tool. No crate, no npm pkg, no GitHub repo. Intended tool is **`oas_generator`** by CrowdHailer (https://github.com/CrowdHailer/oas_generator) — a Gleam library on Hex, not a CLI. Therefore `oaspec --version` is replaced by a Hex-package-version check.
- Added as Gleam deps:
  - `oas_generator` v2.3.1 (dev_dep)
  - `oas_generator_utils` v1.1.0 (runtime dep)
  - Pulls in `oas` v8.0.1 transitively.
- Invocation pattern: `gleam run -m <dev_module>` calling `oas/generator.build(spec_path, out_dir, name)`. Dev module added in task 04 (regenerate-script).
- `scripts/regenerate.sh` created with pinned versions in header and `postman2openapi` step wired up; the `oas_generator` step is a comment placeholder pending task 04.
- `openapi-generator-cli` (OpenAPITools) has no Gleam template — ruled out.

# Install spec-pipeline toolchain

**Phase:** 0 — Spec Pipeline
**Depends on:** none

## Goal
`postman2openapi` and `oaspec` available on PATH.

## Steps
- [ ] Install Rust toolchain if missing
- [ ] `cargo install postman2openapi-cli`
- [ ] Install `oaspec` (pin version; check [oaspec releases](https://github.com/) for install method)
- [ ] Document exact versions in `scripts/regenerate.sh` header

## Done when
`postman2openapi --version` and `oaspec --version` both succeed.

# Regeneration script + CI drift check

**Phase:** 0 — Spec Pipeline
**Depends on:** 03-generate-gleam-from-openapi

## Goal
One command regenerates spec + Gleam code. CI fails if committed output drifts.

## Steps
- [ ] `scripts/regenerate.sh`: postman → openapi → oaspec generate
- [ ] Add `oaspec generate --check` CI step
- [ ] Document in `README.md` how to regenerate

## Done when
`bash scripts/regenerate.sh` produces no diff on clean tree.

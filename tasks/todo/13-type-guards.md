# Full/Partial type guards

**Phase:** 6 — Types
**Depends on:** 12-facades

## Goal
Mirror JS SDK helpers: `is_full_page`, `is_full_block`, `is_full_data_source`, `is_full_user`, `is_full_comment`.

## Steps
- [ ] Partial vs full response variants in generated/hand-written types: `Full(T)` / `Partial(id)`
- [ ] Guard fns returning `Bool` plus refinement helpers returning `Option(Full)`
- [ ] Tests against cached partial + full responses

## Done when
All 5 guards exist and discriminate correctly on cached fixtures.

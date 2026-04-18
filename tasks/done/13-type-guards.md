# Full/Partial type guards

**Phase:** 6 — Types
**Depends on:** 12-facades

## Goal
Mirror JS SDK helpers: `is_full_page`, `is_full_block`, `is_full_data_source`, `is_full_user`, `is_full_comment`.

## Steps
- [ ] Partial vs full response variants in generated/hand-written types: `Full(T)` / `Partial(id)` — SKIPPED (see Notes; the generated types are already the same record for partial and full)
- [x] Guard fns returning `Bool` plus refinement helpers returning `Option(T)`
- [x] Tests against cached full responses + inline-constructed partial records

## Done when
All 5 guards exist and discriminate correctly on cached fixtures.

## Notes
- `is_full_data_source` omitted: `data_sources` namespace not present in the generated `operations.gleam` (Postman v1 source). Documented in module docstring.
- The other four guards land as: `is_full_user`, `is_full_bot_user` (added because `users.me` returns a different record), `is_full_page`, `is_full_block` (+ `is_full_block_item` for the list-item variant), `is_full_comment` (+ `is_full_comment_response` for the create response). 7 guards + 7 `as_full_*` refinement helpers total.
- "Full" criterion: discriminator fields that only appear on hydrated responses are all `Some`. Specifically: user/bot user → `id + type + object`; page → `id + created_time + last_edited_time + properties`; block → `id + type + created_time + last_edited_time`; comment → `id + created_time + parent + rich_text`. Partial responses from Notion typically only set `id` (and sometimes `object`).
- Skipped the `Full(T) / Partial(id)` variant idea: the generated decoder produces a single record type per endpoint where every field is `Option(_)`, so wrapping in a sum type would mean either a full hand-written decoder (huge) or a runtime-only refinement (no real type-safety win over `as_full_*` returning `Option(T)`). The JS SDK's approach is type-narrowing via TS, which Gleam can't replicate without separate `Full*` newtypes — costly for marginal benefit.
- Refinement helpers (`as_full_*`) return `Option(SameType)`; semantics match `is_full_*` exactly. Useful for `result.try`-style chaining.
- Tests: 11 new (cached full case for `users.me` / `pages.retrieve` / `blocks/children.list`; inline partial + inline full constructions for the rest). 50 tests pass total (was 39; +11).

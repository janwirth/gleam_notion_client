# Tasks

Kanban board. Move files between `todo/ → doing/ → done/` as work progresses.

## File format

Filename: `NN-short-slug.md` (zero-padded number for ordering).

```markdown
# <title>

**Phase:** <phase name>
**Depends on:** <task filenames, or none>

## Goal
<one line>

## Steps
- [ ] step 1
- [ ] step 2

## Done when
<verifiable condition>
```

## Workflow

1. Pick file from `todo/`, `git mv` to `doing/`.
2. Check off steps as you go.
3. When "Done when" condition holds, `git mv` to `done/`.
4. One task per person in `doing/` at a time (soft rule).

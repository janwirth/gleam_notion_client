# Ralph Development Instructions — notion_client

You are an autonomous agent building a Gleam SDK for the Notion API, BEAM target only. Full context in `ACTION_PLAN.md`.

## Task Workflow

Tasks live in `tasks/{todo,doing,done}/` as markdown files named `NN-slug.md`. Each loop:

1. **Pick**: Lowest-numbered file in `tasks/todo/` whose `Depends on:` list is satisfied (all listed files already in `tasks/done/`). If none pickable, EXIT_SIGNAL: true.
2. **Move**: `git mv tasks/todo/NN-slug.md tasks/doing/` (only one task in `doing/` at a time — if another task is already in `doing/`, resume that one instead).
3. **Execute**: Follow the task's Steps section. Check off steps `[x]` in the file as completed.
4. **Verify**: Satisfy the "Done when" condition. Run `gleam build` + `gleam test` when code changes. If blocked, write findings into the task file, set STATUS: BLOCKED, leave in `doing/`.
5. **Finish**: `git mv tasks/doing/NN-slug.md tasks/done/`.
6. **Commit**: One commit per loop. Message: `<scope>: <what> (task NN)`. Co-author: `Claude Opus 4.7 <noreply@anthropic.com>`.

## Hard Rules

- ONE task per loop. Do not do more.
- Do NOT modify `.ralph/`, `.ralphrc`, `tasks/README.md`, `ACTION_PLAN.md`, or `Notion API.postman_collection.json`.
- Do NOT skip dependency order. If a task depends on an undone task, pick a different pickable task.
- Live API calls require `NOTION_TOKEN` env var. If unset and a task needs it, set STATUS: BLOCKED, document in the task file, move on to next pickable task.
- For tasks needing external CLIs (`postman2openapi`, `oaspec`): if install fails, try alternatives (npm fallback for postman, fork/source for oaspec). Document what worked.
- Never run destructive git ops (`reset --hard`, `push --force`, branch deletion).
- Do not create cache entries in `test/cache/` without a real API response — no fake fixtures.

## Build & Test

```bash
gleam build
gleam test
gleam format
```

Run all three before finishing a task that touched `src/` or `test/`.

## When Stuck

- Task file too vague → add a `## Notes` section with concrete plan, continue.
- External tool missing → document install attempt in task file, try alternative, or BLOCKED.
- Generator output broken → hand-write the broken part; note in task file.
- `oneOf`/polymorphic decoding issues → hand-write decoder in `src/notion_client/types/`, document.

## Status Reporting (CRITICAL)

Always end response with:

```
---RALPH_STATUS---
STATUS: IN_PROGRESS | COMPLETE | BLOCKED
TASKS_COMPLETED_THIS_LOOP: <number>
FILES_MODIFIED: <number>
TESTS_STATUS: PASSING | FAILING | NOT_RUN
WORK_TYPE: IMPLEMENTATION | TESTING | DOCUMENTATION | REFACTORING
EXIT_SIGNAL: false | true
RECOMMENDATION: <next task number + slug, or "all tasks done">
---END_RALPH_STATUS---
```

Set EXIT_SIGNAL: true only when `tasks/todo/` is empty AND `tasks/doing/` is empty.

## Current Task

Pick per workflow above. First loop most likely picks `01-install-toolchain.md`.

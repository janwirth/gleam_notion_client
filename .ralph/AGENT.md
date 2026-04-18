# Ralph Agent Configuration — notion_client

## Build

```bash
gleam build
```

## Test

```bash
gleam test
```

## Format

```bash
gleam format
```

## External CLIs (installed per task 01)

```bash
postman2openapi --version
oaspec --version
```

## Environment

Loaded automatically from `.env` by `.ralph/claude-yolo` wrapper.

- `NOTION_TOKEN` — integration token (source: `/home/dev/don/config.json`). Required for record/refresh.
- `NOTION_BOOTSTRAP_PAGE_ID` = `3465cbd3c0c680d7bcc2f8dd15b3a05d`. Root page for cache seeding — every cached response must be reachable by recursing from this page.
- `NOTION_CACHE_MODE` — `replay` (default) | `record` | `refresh`.

## Notes

- BEAM target only (Erlang). No JavaScript.
- Spec source: `Notion API.postman_collection.json` (do not edit).
- Action plan: `ACTION_PLAN.md`.
- Tasks: `tasks/{todo,doing,done}/`.

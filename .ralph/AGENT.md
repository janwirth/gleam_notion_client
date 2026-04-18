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
- `NOTION_BOOTSTRAP_DATABASE_ID` = `3465cbd3c0c6808085c5ca3816c811e1`. Test database "notion_client reference pages". All v2 test pages, property examples, and block variants must live as rows in this database. Tests should create rows via `pages.create` with `parent: { database_id: <id> }`, not under a static page.
- `NOTION_CACHE_MODE` — `replay` (default) | `record` | `refresh`.

## Notes

- BEAM target only (Erlang). No JavaScript.
- Spec source: `Notion API.postman_collection.json` (do not edit).
- Action plan: `ACTION_PLAN.md`.
- Tasks: `tasks/{todo,doing,done}/`.

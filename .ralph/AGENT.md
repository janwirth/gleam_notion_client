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

- `NOTION_TOKEN` — required for live API calls (record/refresh cache modes). Not needed for replay.
- `NOTION_CACHE_MODE` — `replay` (default) | `record` | `refresh`.

## Notes

- BEAM target only (Erlang). No JavaScript.
- Spec source: `Notion API.postman_collection.json` (do not edit).
- Action plan: `ACTION_PLAN.md`.
- Tasks: `tasks/{todo,doing,done}/`.

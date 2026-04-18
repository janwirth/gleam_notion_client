# Client record + request runner

**Phase:** 1 — Core Client
**Depends on:** 03-generate-gleam-from-openapi

## Goal
`Client` config type + low-level `request` function that injects Notion headers.

## Steps
- [ ] `src/notion_client.gleam`: `Client` record with `auth`, `base_url`, `timeout_ms`, `notion_version`, `log_level`, `logger`, `retry`
- [ ] Default constants (`DEFAULT_BASE_URL = "https://api.notion.com"`, `DEFAULT_TIMEOUT_MS`)
- [ ] `new(auth)` constructor
- [ ] `request` fn: injects `Authorization: Bearer`, `Notion-Version`, `Content-Type: application/json`
- [ ] Wire `request` into generated client as the transport

## Done when
Manual test: `notion_client.new(token) |> users.me()` returns `Ok(User)` against live API.

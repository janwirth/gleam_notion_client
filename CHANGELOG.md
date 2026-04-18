# Changelog

All notable changes to `notion_client` are documented here. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the
project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.0]

Initial release.

### Added
- Generated request builders + response decoders for the entire Notion
  REST API surface (`notion_client/operations`, `notion_client/schema`),
  produced from the upstream Postman collection via `oas_generator`.
- `notion_client.Client` with sensible defaults: 30 s timeout, Notion
  version `2022-06-28`, exponential-backoff retries, `Warn`-level stderr
  logger.
- Typed errors (`notion_client/error`) mirroring the JS SDK's
  `NotionClientError` / `APIResponseError` taxonomy.
- Retry policy (`notion_client/retry`) matching JS SDK semantics:
  retries 429 on every method, 500/503 only on idempotent verbs,
  honours `Retry-After`.
- Cursor pagination helpers (`notion_client/pagination`) — `collect`
  (eager) and `iterate` (lazy `Yielder`).
- Ergonomic facades: `notion_client/{users, pages, databases, blocks,
  blocks/children, comments, search}`.
- Full/partial type guards (`notion_client/guards`) for the seven
  shapes Notion returns in degraded form.
- Pluggable structured logger (`notion_client/logging`).
- 57 tests covering decoder cache fixtures, retry behaviour, facade
  request shapes, guard discriminators, pagination, and logging.

[1.0.0]: https://github.com/janwirth/gleam_notion_client/releases/tag/v1.0.0

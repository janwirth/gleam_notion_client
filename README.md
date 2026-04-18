# notion_client

[![Package Version](https://img.shields.io/hexpm/v/notion_client)](https://hex.pm/packages/notion_client)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/notion_client/)

```sh
gleam add notion_client@1
```
```gleam
import notion_client

pub fn main() -> Nil {
  // TODO: An example of the project in use
}
```

Further documentation can be found at <https://hexdocs.pm/notion_client>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```

## Regenerating the SDK

The Notion API surface is described by `Notion API.postman_collection.json`.
`bash scripts/regenerate.sh` rebuilds everything downstream:

```
postman2openapi → fix_openapi.mjs → spectral lint → oas_generator
                → patch utils import → dedupe Anon defs → gleam format → gleam build
```

Required tools: `postman2openapi-cli` v1.2.1 (cargo), `node` (for the JS helpers
and `npx @stoplight/spectral-cli`), `gleam` 1.15.4 plus the OTP toolchain.

Run it after editing the postman collection or bumping `oas_generator`. Commit
the resulting diff to `openapi.json`, `src/notion_client/operations.gleam`, and
`src/notion_client/schema.gleam`. The `regenerate-check` GitHub Actions
workflow runs the same script on every PR and fails if the committed output
drifts from a fresh regeneration.

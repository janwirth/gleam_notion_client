#!/usr/bin/env bash
# Regenerate Gleam SDK from Notion postman collection.
#
# Toolchain versions (pinned 2026-04-18):
#   postman2openapi-cli  v1.2.1   (cargo install postman2openapi-cli)
#   oas_generator        v2.3.1   (Gleam dev_dep, hex)
#   oas_generator_utils  v1.1.0   (Gleam runtime dep, hex)
#   spectral-cli         latest   (npx @stoplight/spectral-cli)
#   gleam                1.15.4
#   rustc                1.92.0
#   node                 (any)
#
# NOTE: original task referenced `oaspec` CLI. No such tool exists for Gleam.
# Substituted CrowdHailer/oas_generator (Gleam library, no CLI binary).
# Invoked via `gleam run -m <module>` — see later tasks for the dev module.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

POSTMAN_COLLECTION="Notion API.postman_collection.json"
OPENAPI_OUT="openapi.json"

echo "==> postman2openapi: $POSTMAN_COLLECTION -> $OPENAPI_OUT"
postman2openapi "$POSTMAN_COLLECTION" -f json > "$OPENAPI_OUT"

echo "==> fix_openapi: nullable-without-type, trailing-slash paths, text.link"
node scripts/fix_openapi.mjs "$OPENAPI_OUT"

echo "==> spectral lint: $OPENAPI_OUT"
npx --yes @stoplight/spectral-cli lint "$OPENAPI_OUT" --fail-severity=error

echo "==> oas_generator: invoke via dev module (added in task 04)"
# gleam run -m notion_client/dev/regen

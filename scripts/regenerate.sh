#!/usr/bin/env bash
# Regenerate Gleam SDK from Notion postman collection.
#
# Toolchain versions (pinned 2026-04-18):
#   postman2openapi-cli  v1.2.1   (cargo install postman2openapi-cli)
#   oas_generator        v2.3.1   (Gleam dev_dep, hex)
#   oas_generator_utils  v1.1.0   (Gleam runtime dep, hex)
#   gleam                1.15.4
#   rustc                1.92.0
#
# NOTE: original task referenced `oaspec` CLI. No such tool exists for Gleam.
# Substituted CrowdHailer/oas_generator (Gleam library, no CLI binary).
# Invoked via `gleam run -m <module>` — see later tasks for the dev module.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

POSTMAN_COLLECTION="Notion API.postman_collection.json"
OPENAPI_OUT="priv/notion.openapi.json"

mkdir -p priv

echo "==> postman2openapi: $POSTMAN_COLLECTION -> $OPENAPI_OUT"
postman2openapi -f "$POSTMAN_COLLECTION" -o "$OPENAPI_OUT" --format json

echo "==> oas_generator: invoke via dev module (added in later task)"
# gleam run -m notion_client/dev/regen

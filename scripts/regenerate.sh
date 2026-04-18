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

echo "==> truncate prior facade in src/notion_client.gleam (so dev module compiles)"
node -e "const fs=require('fs');const p='src/notion_client.gleam';const s=fs.readFileSync(p,'utf8');const m=s.match(/^.*?\/\/ GENERATED[^\n]*\n/s);if(!m)throw new Error('marker missing');fs.writeFileSync(p,m[0]);"

echo "==> oas_generator: gleam run -m notion_client/dev"
gleam run -m notion_client/dev

echo "==> truncate generated facade in src/notion_client.gleam (BEAM keeps stub only)"
node -e "const fs=require('fs');const p='src/notion_client.gleam';const s=fs.readFileSync(p,'utf8');const m=s.match(/^.*?\/\/ GENERATED[^\n]*\n/s);if(!m)throw new Error('marker missing');fs.writeFileSync(p,m[0]);"

echo "==> patch utils import: oas/generator/utils -> notion_client/internal/utils"
node -e "const fs=require('fs');for(const p of ['src/notion_client/operations.gleam','src/notion_client/schema.gleam']){const s=fs.readFileSync(p,'utf8');fs.writeFileSync(p,s.replace(/import oas\/generator\/utils/g,'import notion_client/internal/utils'));}"

echo "==> dedupe Anon types/encoders/decoders"
node scripts/dedupe_anons.mjs src/notion_client/operations.gleam

echo "==> gleam format (deterministic output: imports + line wrapping)"
gleam format

echo "==> gleam build"
gleam build

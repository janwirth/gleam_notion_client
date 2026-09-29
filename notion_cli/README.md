# notion_cli

Agent-facing Notion CLI. Two verbs. Built on [`notion_client`](..).

- `fetch <page_id>` — render a Notion page (recursively) as markdown
  with **block-id annotations** so an agent can address any block.
- `check <block_id>` — flip a `to_do` checkbox on Notion.

## Install / run

```sh
cd notion_cli
gleam run -- fetch <page_id> -o page.md
gleam run -- check  <block_id>
gleam run -- check  <block_id> --uncheck
```

`NOTION_TOKEN` must be set (integration token with access to the
target page). `NOTION_PAGE_ID` is an optional fallback used by `fetch`
when the positional `<page_id>` is omitted. `NOTION_API_VERSION` is
optional.

## Block-id annotations

Each block is preceded by a markdown link-label comment carrying its
Notion block id. Comments are invisible in any renderer but trivially
grepable:

```markdown
[//]: # (notion_block_id: 1f9e6c34-1234-4abc-9ff0-0c52e8e3c111)
- [ ] buy milk
[//]: # (notion_block_id: 1f9e6c34-5678-4def-9ff0-0c52e8e3c222)
- [x] ship release
```

Agent workflow:

1. `notion_cli fetch <page_id> -o page.md`
2. Read `page.md`, pick the `[//]: # (notion_block_id: …)` above the
   `- [ ]` item to tick.
3. `notion_cli check <that-id>`.

## Scope

Only `to_do` blocks are supported for `check`. Database-row checkbox
properties use a different API and are out of scope.

For appending / updating / creating pages, use the `notion_client`
binary directly.

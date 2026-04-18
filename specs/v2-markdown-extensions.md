# v2 — Markdown ↔ Notion extensions

Spec for extending the CLI's `read`/`append` conversion beyond v1.

## Status

Spec. Not implemented. Tasks in `tasks/todo/` to follow.

## v1 recap

Current scope: `paragraph`, `heading_1/2/3`, `bulleted_list_item`, `numbered_list_item`, `to_do`, `code`, `quote`, `divider`. Plain-text rich text only. No nesting preserved on write. Unsupported types render as `<!-- unsupported: TYPE -->`.

## v2 goals

Add: tables, iframes (embeds), full rich-text annotations + links, nested lists (both directions), images, recursive child-page inlining, synced blocks, page properties (YAML frontmatter).

## v2 non-goals

- Equations (`$…$` LaTeX) — defer to v3.
- Mentions of users/pages/databases in rich text — render as `[name](notion:id)` passthrough only, no lookup.
- Callouts, toggles, columns, column lists — defer to v3 (needs design around HTML-adjacent syntax).
- Creating synced-block originals from markdown (write path is read-only for synced blocks).
- Creating database pages with typed properties via `append` (new `create` subcommand covers this separately).

## Format by format

Each block form below specifies **read** (Notion → markdown), **write** (markdown → Notion), and **edge cases**.

---

### 1. Rich text (annotations + links)

Notion rich-text item shape (simplified):

```json
{
  "type": "text",
  "text": { "content": "hello", "link": { "url": "https://…" } },
  "annotations": {
    "bold": false, "italic": false, "strikethrough": false,
    "underline": false, "code": false, "color": "default"
  },
  "plain_text": "hello",
  "href": "https://…"
}
```

**Markdown syntax** (CommonMark + GFM + minimal HTML):

| Annotation | Markdown |
|------------|----------|
| bold | `**text**` |
| italic | `*text*` |
| strikethrough | `~~text~~` |
| code | `` `text` `` |
| link | `[text](url)` |
| underline | `<u>text</u>` (HTML passthrough) |
| color | `<span style="color:NAME">text</span>` (HTML passthrough) |
| combined | nest: `**[_bold link_](url)**` |

**Read direction**

- Concatenate `rich_text` array. For each item, wrap `plain_text` in annotation markers in canonical order: `code` → `strike` → `bold` → `italic` → `underline` → `span-color` (innermost → outermost), then wrap in `[…](href)` if `href` present.
- Collapse adjacent items with identical annotations + same link before wrapping (avoid `**a****b**`).
- Escape `*`, `_`, `` ` ``, `[`, `]`, `\` in `plain_text` before wrapping.

**Write direction**

- Inline parser scans for `**`, `*`, `~~`, `` ` ``, `[…](…)`, `<u>`, `</u>`, `<span style="color:…">`, `</span>`.
- Produce a flat list of `{text, bold, italic, strikethrough, code, underline, color, href}` runs.
- Emit each run as a Notion rich_text `text` item.
- Escaped chars (`\*`, `\[`, etc.) preserved as literals.
- Unknown HTML tags kept verbatim in `plain_text` (best effort).

**Edge cases**

- Nested identical emphasis (`**foo _bar_ baz**`) → parser tracks stack.
- Unclosed emphasis → treat opener as literal.
- Link text may contain emphasis; emphasis cannot span across a link boundary.
- Notion's `equation` rich-text type → render as `$expr$` on read; on write, `$…$` remains as literal text (equations deferred).
- Notion's `mention` → render as `[@Name](notion-mention:id)` on read; on write, preserved as plain link (no mention reconstruction).

---

### 2. Nested lists

**Read**

- Recurse `has_children` on `bulleted_list_item` / `numbered_list_item`.
- Indent children by 2 spaces per level (GFM-compatible).
- Numbered siblings restart at 1; numbering re-derived on read.

**Write**

- Parse leading spaces; every 2 spaces = one level.
- Build tree: each `- ` / `N. ` at indent level `i` becomes a child of the nearest prior item at level `i-1`.
- Tab characters = 4 spaces. Mixed indentation → warning log, align to detected step.
- Max nesting depth: 10 (Notion allows more but deep nesting is rarely intended).
- Emit with `children: [...]` on each list-item block JSON.

**Edge cases**

- Non-list content under a list item (paragraph continuation): paragraph block becomes child of the list item.
- Gap lines between items of same level preserved (no effect on block structure, but kept for re-read fidelity).

---

### 3. Tables

Notion: `table` block with `has_children: true`, `table_width`, `has_column_header`, `has_row_header`. Children are `table_row` blocks whose `cells` is `List(List(RichText))`.

**Markdown**: GFM table syntax.

```markdown
| col1 | col2 |
|------|------|
| a    | b    |
```

**Read**

- Fetch table children (rows).
- First row → header if `has_column_header = true`; otherwise add a blank header row (GFM requires one).
- Render each row as `| c1 | c2 | … |`.
- Cells may contain rich text; pipe chars inside cells escaped as `\|`.
- Separator row: `| --- | --- |` per column. If `has_row_header`, first column separator is `| :--- |` (left-align hint, lossy but preserves intent).

**Write**

- Detect GFM table: 3+ consecutive lines, second line is `|[-: ]+|[-: |]+`.
- Parse header from line 1, alignment from line 2, rows from remaining lines.
- Split each row on `|`, rejecting empty outer segments.
- Each cell → `rich_text` array (pipe-through rich-text write path).
- Emit `table` block with `children: [table_row, …]`.
- `has_column_header = true` since markdown tables always have a header row.
- `has_row_header` = true if line-2 left-aligns only the first column.

**Edge cases**

- Mismatched column counts → pad shorter rows with empty cells.
- Multi-line cells (GFM `<br>`) → preserved as literal `<br>` in rich text.
- Tables inside list items: supported via nesting (append as child of list item).

---

### 4. Iframes / embeds

Notion: `embed` block with `{ url, caption: RichText[] }`.

**Markdown**: raw HTML iframe passthrough.

```markdown
<iframe src="https://www.example.com/widget"></iframe>
```

**Read**

- `embed` → `<iframe src="URL"></iframe>`.
- If `caption` present, render caption as a following italic paragraph: `*caption text*`.

**Write**

- Detect a full-line `<iframe …></iframe>` (attrs parsed minimally, only `src` used).
- Convert to `embed` block with parsed `src`.
- Captions not parsed from markdown (no reverse convention); to set captions, use the Notion UI.

**Edge cases**

- `<iframe/>` self-closing: accepted.
- Multi-line iframe spread over lines: not supported (v2 requires single-line).
- Other `bookmark` / `link_preview` blocks: render as `[URL](URL)` on read. Write path does not attempt reverse — URLs become plain rich-text links, landing as paragraphs in Notion.

---

### 5. Images

Notion: `image` block with `file` (Notion-hosted) or `external` (URL) variants plus `caption: RichText[]`.

**Markdown**:

```markdown
![caption](url)
```

**Read**

- `image.file.url` (signed URL, time-limited) OR `image.external.url`.
- Caption: rendered as alt text — `![caption](url)`.
- Prefer `external.url` when available; note `file.url` expires ~1h so saved markdown has stale links. Emit warning log when serialising `file`-hosted images to markdown.

**Write**

- Line matching `^!\[caption\]\(url\)$` → `image` block with `type: "external", external: {url}` and caption rich text.
- Notion-hosted uploads: not supported (requires multipart upload).
- Data URIs: not supported.

**Edge cases**

- Inline images (`![…](…)` mid-paragraph): rejected in v2; only top-level image lines convert. Inline `![…]` in paragraphs degrades to rich-text literal.

---

### 6. Child pages (recursive inlining)

Notion: `child_page` block with `title`. To fetch its content, call `/v1/blocks/{child_page_id}/children`.

**Markdown**: heading + marker + recursive content, bracketed by HTML comments.

```markdown
<!-- child_page:ID depth=2 -->
## Child Page Title

… recursively rendered content …

<!-- /child_page:ID -->
```

**Read**

- For each `child_page` block: render heading `## <title>` (level offset = parent depth + 1, clamped to h6).
- Recurse into page via `/v1/blocks/{id}/children`.
- Enforce `--max-depth N` (default 3). Beyond depth, render `<!-- child_page:ID (depth limit) -->` stub with no content.
- Maintain visited-set; on cycle, emit `<!-- child_page:ID (cycle) -->` stub.
- Emit open + close HTML comments so a future writer can round-trip.

**Write**

- Detect `<!-- child_page:ID -->` … `<!-- /child_page:ID -->` blocks.
- If ID is empty/new: create a new subpage via `pages.create` with `parent: {page_id: …}`, appending the inner markdown after.
- If ID exists: append inner markdown to that page.
- Without the HTML-comment markers, write path ignores `## Heading` as a plain heading (no child-page conversion).

**Edge cases**

- Child databases (`child_database`) — v2 renders as `<!-- child_database:ID title="…" -->` stub only (no row inlining). Write path: creates no database.
- Recursion budget: default 3 levels; flag `--max-depth` on `read`.
- Rate limits: a deeply recursive read may hit 3 rps. Reuse existing retry logic.

---

### 7. Synced blocks

Notion: `synced_block` has `synced_from: null` (original) or `synced_from: {block_id}` (reference).

**Markdown** (read-only):

Original:
```markdown
<!-- synced_block:ID -->
… content …
<!-- /synced_block:ID -->
```

Reference:
```markdown
<!-- synced_from:ID -->
```

**Read**

- Original (`synced_from: null`): fetch children, wrap in open/close comments with the block id. This is the "source of truth".
- Reference: emit `<!-- synced_from:ID -->` stub. Do NOT fetch original content (avoid duplication). Optional `--inline-synced` flag to inline content from original.

**Write**

- Synced blocks are **not** created from markdown in v2. Both comment forms above are ignored (pass through as literal HTML comments).
- Documented limitation. Users edit synced blocks via the Notion UI.

**Edge cases**

- `--inline-synced` + cycle through original referencing itself → visited-set per read invocation.

---

### 8. Page properties (YAML frontmatter)

Page properties only exist when the page is a row in a database (parent type `database_id` / `data_source_id`). Property types covered:

| Notion type | YAML value | Notes |
|-------------|------------|-------|
| title | string | Already the page title; exclude from frontmatter |
| rich_text | string | Plain-text flattened; annotations lost |
| number | number / null | |
| select | string / null | Option name |
| multi_select | list of strings | |
| date | `{ start, end?, time_zone? }` or string | ISO-8601 |
| people | list of user ids | |
| files | list of URLs | |
| checkbox | bool | |
| url | string | |
| email | string | |
| phone_number | string | |
| status | string | Option name |
| relation | list of page ids | |
| unique_id | string (`prefix-N`) | read-only |
| formula | value only | read-only, derived |
| rollup | value only | read-only, derived |
| created_time | ISO-8601 | read-only |
| last_edited_time | ISO-8601 | read-only |
| created_by | user id | read-only |
| last_edited_by | user id | read-only |

**Markdown output**

```markdown
---
id: 3465cbd3-c0c6-80d7-bcc2-f8dd15b3a05d
url: https://www.notion.so/…
title: My Entry
properties:
  Status: In progress
  Tags: [urgent, backend]
  Due: 2026-04-30
  Estimate: 5
  Shipped: false
---

# My Entry

<body markdown…>
```

**Read**

- `pages.retrieve` returns `properties`. Emit as YAML frontmatter block at the top of the output, under `properties:`.
- Read-only property types (formula, rollup, created_time, …) emitted under `properties_readonly:` for clarity. Editing that sub-block has no effect on write.
- Empty / null values emitted as `null`. Skip keys whose value is null unless `--full-properties`.

**Write**

- `append` subcommand: frontmatter (if present) is ignored. Body below is appended as blocks.
- New `update` subcommand: reads frontmatter, PATCHes `/v1/pages/{id}` with the property diff. Body below, if present, also appended.
- Properties absent from frontmatter are left untouched (not cleared). Explicit `null` clears a property.

**Edge cases**

- Property name with colon / special chars: YAML-quote.
- Unknown property type on read: emit as `null` with a `_comment` line.
- Schema mismatch on update (property missing from DB): return API error verbatim.

---

## New CLI surface

```text
notion_client read <page_id>
    [--write-file]
    [--max-depth N]        (v2, default 3, for child_page recursion)
    [--inline-synced]      (v2, expand synced_from references inline)
    [--full-properties]    (v2, include null + read-only props in frontmatter)

notion_client append <page_id> <markdown>
notion_client append <page_id> --from-file <path>
    (body only; frontmatter ignored)

notion_client update <page_id> --from-file <path>      (v2, new)
    (applies frontmatter properties via PATCH; body, if any, appended)
```

## Implementation phases

Each phase = one task file, independently shippable.

| # | Phase | Read | Write | Tests |
|---|-------|------|-------|-------|
| 16 | Rich text annotations + links | ✓ | ✓ | unit: markdown↔rich-text round-trip |
| 17 | Nested lists | ✓ | ✓ | unit: depth 3+, mixed numbered/bulleted |
| 18 | Images | ✓ | ✓ (external only) | unit + live append |
| 19 | Iframes / embeds | ✓ | ✓ | unit + live append |
| 20 | Tables | ✓ | ✓ | unit: align, pipe escape; live |
| 21 | Child-page recursion (read) | ✓ | passthrough | depth limit + cycle test |
| 22 | Child-page creation (write) | — | ✓ | live: new subpage round-trip |
| 23 | Synced blocks (read) | ✓ | ignore | unit: original + reference rendering |
| 24 | Properties frontmatter (read) | ✓ | — | fixture: page in DB, varied types |
| 25 | `update` subcommand | — | ✓ | live: PATCH a property, verify |

Phases 16-20 land first (pure content). 21-22 + 24-25 add cross-cutting concerns (recursion, properties). 23 is read-only until a future design.

## Testing strategy

All live tests run against `NOTION_BOOTSTRAP_DATABASE_ID = 3465cbd3c0c6808085c5ca3816c811e1` ("notion_client reference pages"). Each test creates a fresh row via `pages.create` with `parent: { database_id: <id> }`, exercises the feature, and leaves the row in place as a visible fixture. Schema evolves as phases land — phase 24 specifically grows the DB's property palette (rich_text, select, multi_select, date, number, checkbox, url, email, phone_number, status).

- **Unit**: per-block `to_markdown` / `from_markdown` round-trip tests with canned JSON fixtures and canned markdown. Target: every block type in this spec has at least 2 unit tests.
- **Integration**: each phase ends with `pages.create` under the reference DB, then append + read, asserting round-trip preserves content (modulo documented lossy fields: underline/color may normalise, signed image URLs change).
- **Property tests** (optional): randomised rich-text runs → encode → decode → assert plain-text preserved.
- **Fixtures**: extend `test/cache/` with one captured response per block type; decoder test suite already iterates all results.

## Breaking changes vs v1

- `--write-file` flag gains sibling `--max-depth` — v1 invocations still work.
- v1 produced `<!-- unsupported: … -->` stubs for blocks we now support; readers diffing historical output will see different markdown. Acceptable; no persisted format guarantees yet.
- Appended markdown with GFM tables previously rendered as paragraphs; v2 parses them as tables. Users who relied on literal table markdown in a paragraph must escape pipes (`\|`).

## Open questions

1. **Color preservation** — HTML `<span>` tags pollute markdown. Alternative: drop colors on read (lossy but clean), gate behind `--preserve-colors`. Default lean: drop, opt-in to preserve.
2. **Rich text in code blocks** — Notion code blocks can technically have annotations; we flatten to plain text on read. OK to keep lossy.
3. **File uploads for images** — requires multipart + signed URL workflow. Defer to v3 unless requested.
4. **Property update atomicity** — if a PATCH fails mid-set, we leave the page partially updated. Wrap in a dry-run flag for v2? Default to best-effort.

## Out of scope

- Two-way sync / diffing.
- Markdown → new-page creation (separate `create` command; deferred).
- Rendering of `database_id` parent pages (databases) as a whole — only individual rows.
- Equation blocks, PDF blocks, file blocks, audio/video blocks — v3.

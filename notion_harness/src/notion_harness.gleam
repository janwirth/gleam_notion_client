/// notion_harness — agent-facing convenience wrapper for the `notion_cli` binary.
///
/// Does not invoke notion_cli itself. Instead it exposes the usage text so
/// programs like empress can inject it into an LLM's system prompt, letting
/// the LLM call `notion_cli fetch` / `notion_cli check` as tools.
///
/// Also exposes `find_princess_callout/1` for empress' cold-start flow so the
/// server can show the current open todos from the page's princess callout
/// WITHOUT spinning up Claude first.
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

pub const usage_instructions: String = "notion_cli (on PATH). IDs: dashed or 32-hex, both work.

  fetch <page_id> [-o path] [--empress-only]   md dump; blocks tagged
      '[//]: # (notion_block_id: <ID>)' above each line. --empress-only
      skips ✅ done callout's contents. No path: prints to stdout.
  check <block_id> [--uncheck]        toggle to_do checked state.
  comment <page_id|--block ID> text   add comment; --block = inline on that block.
  iframe <page_id> <url>  (embed)     append embed block, prints id.
  princess <page_id> [--json] [--all] find 👸 callout + to_do children
      (open only, unless --all). Each todo carries a `note` field: text
      from any non-todo child block written under that checkbox.
  princess create <page_id>           create 👸 callout, prints id (appended at end).

WORKFLOW: fetch --empress-only -o page.md -> grep -B1 '^- \\[ \\]' for ids ->
comment --block ID \"Working on…\" -> implement/verify -> pass: comment
--block ID \"Done: …\" then check ID  |  fail: leave unchecked, comment
--block ID \"Blocked: …\"  |  unclear: comment question, leave unchecked.
There is no `checkmark`/`done` subcommand — checking the box is enough;
move it into a done callout manually in Notion if you keep one.
Independent todos: parallel subagents, one per todo/cluster.

ENV: NOTION_TOKEN (required), NOTION_PAGE_ID, NOTION_API_VERSION.
Exit 0 ok, 1 error.
"

pub fn usage() -> String {
  usage_instructions
}

/// A to_do block under the princess callout that is still open (i.e.
/// `checked = false`). `id` is the Notion block id, usable verbatim
/// with `notion_cli check <id>` to tick the box. `depth` is the
/// to_do's nesting level under the callout (0 = direct child); used
/// by callers to render visual indentation in lists / prompts.
pub type PrincessTodo {
  PrincessTodo(
    id: String,
    text: String,
    checked: Bool,
    depth: Int,
    note: String,
  )
}

/// Result of searching the page for the princess-emoji callout block.
/// `Found` carries the callout's own block id, the list of open to_do
/// children, and `content_markdown` — the rendered markdown of the
/// callout's own rich_text header plus any non-todo child blocks
/// (paragraphs, bullets, headings, code, etc.) that hold workflow
/// notes / specific instructions. `Missing` means no callout with 👸
/// was found. `LookupError` surfaces CLI / API / parse failures —
/// treated the same as Missing for UI purposes but kept separate so
/// callers can log why.
pub type PrincessLookup {
  Found(
    callout_block_id: String,
    todos: List(PrincessTodo),
    content_markdown: String,
  )
  Missing
  LookupError(message: String)
}

/// Shell out to `notion_cli princess <page_id> --json` and parse the
/// structured output into a [`PrincessLookup`](#PrincessLookup).
///
/// Inherits the notion_cli environment (NOTION_TOKEN, NOTION_API_VERSION)
/// from the current process; assumes `notion_cli` is on $PATH. Use this
/// from an empress server so you can render the open-todo list BEFORE
/// handing anything to Claude.
pub fn find_princess_callout(page_id: String) -> PrincessLookup {
  let cmd =
    "notion_cli princess "
    <> shell_quote(page_id)
    <> " --json 2>/dev/null"
  let raw = string.trim(os_cmd(cmd))
  case raw {
    "" -> LookupError("notion_cli produced no output for page " <> page_id)
    _ -> parse_princess_json(raw)
  }
}

/// Like `find_princess_callout`, but requests `--all` from notion_cli so
/// the returned `todos` include BOTH open and checked items (with
/// `checked` reflecting their state). Use this in views that need to
/// visualize completed todos alongside open ones.
pub fn find_princess_callout_all(page_id: String) -> PrincessLookup {
  let cmd =
    "notion_cli princess "
    <> shell_quote(page_id)
    <> " --all --json 2>/dev/null"
  let raw = string.trim(os_cmd(cmd))
  case raw {
    "" -> LookupError("notion_cli produced no output for page " <> page_id)
    _ -> parse_princess_json(raw)
  }
}

/// Shell out to `notion_cli title <page_id>` and return the page's title
/// as `Some(title)`, or `None` when the page has no title, the CLI
/// produces no output, or the lookup fails. Used by empress to render
/// the page name in the browser tab `<title>`, falling back to the
/// project path when this returns `None`.
///
/// Synchronous: blocks the calling process for the duration of the
/// Notion API round-trip. Acceptable here because the call only
/// happens once per shell render (HTML page load), which already
/// shells out to `notion_cli princess` for the open-todos panel.
pub fn fetch_page_title(page_id: String) -> Option(String) {
  let cmd = "notion_cli title " <> shell_quote(page_id) <> " 2>/dev/null"
  let raw = string.trim(os_cmd(cmd))
  case raw {
    "" -> None
    "untitled" -> None
    t -> Some(t)
  }
}

/// Shell out to `notion_cli princess create <page_id>`; on success returns
/// the newly created callout's block id.
pub fn create_princess_callout(page_id: String) -> Result(String, String) {
  let cmd = "notion_cli princess create " <> shell_quote(page_id) <> " 2>&1"
  let raw = string.trim(os_cmd(cmd))
  case raw {
    "" -> Error("notion_cli produced no output")
    _ ->
      case string.starts_with(raw, "error:") {
        True -> Error(raw)
        False ->
          case is_uuid_like(raw) {
            True -> Ok(raw)
            False -> Error("unexpected notion_cli output: " <> raw)
          }
      }
  }
}

/// Parse the JSON emitted by `notion_cli princess --json`. Exposed for
/// tests + callers that already have the raw output (e.g. piped from
/// a shell script).
pub fn parse_princess_json(raw: String) -> PrincessLookup {
  case json.parse(raw, princess_decoder()) {
    Ok(v) -> v
    Error(_) -> LookupError("could not parse notion_cli JSON: " <> raw)
  }
}

fn princess_decoder() -> decode.Decoder(PrincessLookup) {
  use status <- decode.field("status", decode.string)
  case status {
    "missing" -> decode.success(Missing)
    "found" -> {
      use callout_id <- decode.field("callout_block_id", decode.string)
      use todos <- decode.field("todos", decode.list(princess_todo_decoder()))
      // content_markdown is optional for back-compat with older
      // notion_cli builds that don't emit the field.
      use content_markdown <- decode.optional_field(
        "content_markdown",
        "",
        decode.string,
      )
      decode.success(Found(callout_id, todos, content_markdown))
    }
    other -> decode.success(LookupError("unknown status: " <> other))
  }
}

fn princess_todo_decoder() -> decode.Decoder(PrincessTodo) {
  use id <- decode.field("id", decode.string)
  use text <- decode.field("text", decode.string)
  use checked <- decode.field("checked", decode.bool)
  // Older notion_cli builds didn't emit `depth`/`note`; fall back so
  // upgrading the library doesn't require a lockstep CLI rebuild.
  use depth <- decode.optional_field("depth", 0, decode.int)
  use note <- decode.optional_field("note", "", decode.string)
  decode.success(PrincessTodo(
    id: id,
    text: text,
    checked: checked,
    depth: depth,
    note: note,
  ))
}

fn is_uuid_like(s: String) -> Bool {
  // Accept 32-hex or dashed UUID; good enough to reject the
  // "error: …" path while staying permissive.
  let hex_chars = [
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e",
    "f", "A", "B", "C", "D", "E", "F", "-",
  ]
  let n = string.length(s)
  { n == 32 || n == 36 }
  && list.all(string.to_graphemes(s), fn(g) { list.contains(hex_chars, g) })
}

fn shell_quote(s: String) -> String {
  "'" <> string.replace(s, "'", "'\\''") <> "'"
}

@external(erlang, "notion_harness_ffi", "os_cmd")
fn os_cmd(cmd: String) -> String

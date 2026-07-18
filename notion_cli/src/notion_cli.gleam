//// notion_cli — agent-facing Notion CLI.
////
//// ```text
//// notion_cli fetch <page_id> [-o <path>]
//// notion_cli check <block_id> [--uncheck]
//// notion_cli comment <page_id> <text>
//// notion_cli comments <block_or_page_id> [--json]
//// notion_cli iframe <page_id> <url>
//// notion_cli title <page_id>
//// ```
////
//// `fetch` requires a page id; if the positional argument is omitted
//// it is read from `NOTION_PAGE_ID`.
////
//// Env:
//// - `NOTION_TOKEN` (required)
//// - `NOTION_PAGE_ID` (optional) — fallback page id for `fetch`
//// - `NOTION_API_VERSION` (optional)

import argv
import envoy
import gleam/bit_array
import gleam/dict
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import notion_client.{type Client}
import notion_client/error.{type NotionError}
import notion_client/markdown.{type AnnotatedBlock, type Block, AnnotatedBlock}
import simplifile

pub fn main() -> Nil {
  load_dotenv()
  case argv.load().arguments {
    ["fetch"] -> cmd_fetch_env(None, False)
    ["fetch", "--empress-only"] -> cmd_fetch_env(None, True)
    ["fetch", "-o", path] -> cmd_fetch_env(Some(path), False)
    ["fetch", "--empress-only", "-o", path] -> cmd_fetch_env(Some(path), True)
    ["fetch", "-o", path, "--empress-only"] -> cmd_fetch_env(Some(path), True)
    ["fetch", page_id] -> cmd_fetch(page_id, None, False)
    ["fetch", page_id, "--empress-only"] -> cmd_fetch(page_id, None, True)
    ["fetch", "--empress-only", page_id] -> cmd_fetch(page_id, None, True)
    ["fetch", page_id, "-o", path] -> cmd_fetch(page_id, Some(path), False)
    ["fetch", page_id, "--empress-only", "-o", path] ->
      cmd_fetch(page_id, Some(path), True)
    ["fetch", page_id, "-o", path, "--empress-only"] ->
      cmd_fetch(page_id, Some(path), True)
    ["fetch", "--empress-only", page_id, "-o", path] ->
      cmd_fetch(page_id, Some(path), True)
    ["check", block_id] -> cmd_check(block_id, True)
    ["check", block_id, "--uncheck"] -> cmd_check(block_id, False)
    ["done", block_id] -> cmd_done(block_id)
    ["comment", "--block", block_id, ..rest] ->
      cmd_comment_block(block_id, string.join(rest, " "))
    ["comment", "-b", block_id, ..rest] ->
      cmd_comment_block(block_id, string.join(rest, " "))
    ["comment", page_id, ..rest] -> cmd_comment(page_id, string.join(rest, " "))
    ["comments", id] -> cmd_comments(id, False)
    ["comments", id, "--json"] -> cmd_comments(id, True)
    ["comments", "--json", id] -> cmd_comments(id, True)
    ["princess", "create", page_id] -> cmd_princess_create(page_id)
    ["princess", page_id] -> cmd_princess(page_id, False, False)
    ["princess", page_id, "--json"] -> cmd_princess(page_id, True, False)
    ["princess", "--json", page_id] -> cmd_princess(page_id, True, False)
    ["princess", page_id, "--all"] -> cmd_princess(page_id, False, True)
    ["princess", page_id, "--all", "--json"] -> cmd_princess(page_id, True, True)
    ["princess", page_id, "--json", "--all"] -> cmd_princess(page_id, True, True)
    ["princess", "--all", page_id] -> cmd_princess(page_id, False, True)
    ["princess", "--all", "--json", page_id] -> cmd_princess(page_id, True, True)
    ["princess", "--json", "--all", page_id] -> cmd_princess(page_id, True, True)
    ["checkmark", "ensure", page_id] -> cmd_checkmark_ensure(page_id)
    ["checkmark", "move", block_id] -> cmd_checkmark_move(block_id)
    ["iframe", page_id, url] -> cmd_iframe(page_id, url)
    ["embed", page_id, url] -> cmd_iframe(page_id, url)
    ["title", page_id] -> cmd_title(page_id)
    _ -> print_help()
  }
}

fn print_help() -> Nil {
  io.println(
    "notion_cli — agent-facing Notion CLI.

Designed to be composable from a shell or an agent.

COMMANDS
  fetch <page_id> [-o <path>] [--empress-only]
      Recursively fetch a Notion page and render as markdown.
      Every block is preceded by an HTML-invisible comment carrying
      its Notion block id:

          [//]: # (notion_block_id: 1f9e6c34-1234-4abc-9ff0-0c52e8e3c111)
          - [ ] buy milk

      Without -o: prints to stdout.
      With    -o: writes the file and prints the path on stdout.
      If <page_id> is omitted, falls back to $NOTION_PAGE_ID.
      With --empress-only: don't recurse into the ✅ 'done' callout's
      contents. The callout header still renders, but its list of
      completed tasks stays folded so the fetched markdown reflects
      only the open (empress) work.

  check <block_id> [--uncheck]
      Toggle a to_do block's checked state on Notion.
      Default: sets checked=true. With --uncheck: sets checked=false.
      Fails (exit 1) if the block is not of type \"to_do\".
      Prints \"ok\" on success.

  comment <page_id> <text>
  comment --block <block_id> <text>   (alias: -b)
      Add a comment to a Notion page (default) or to a specific
      block. The block form is what to use when you want the comment
      to attach to an individual to_do / paragraph / etc. — Notion
      will then render the comment thread inline on that block
      rather than at the page level. All remaining args are joined
      with spaces and posted as a single paragraph. Prints \"ok\"
      on success.

  checkmark ensure <page_id>
      Get-or-create the ✅ \"done\" callout on the page. If a callout
      with the ✅ emoji already exists, prints its block id. Otherwise
      creates one — positioned right after the 👸 empress callout when
      one is present, or appended to the page otherwise — and prints
      the new block id.

  checkmark move <block_id>
      Move a completed to_do into the ✅ callout on its page. Ensures
      the checkmark callout exists (creating it if not), appends a
      checked copy of the to_do as a child of that callout, then
      archives the original block. Walks parent pointers so the todo
      can be nested arbitrarily under the empress callout. Prints the
      new to_do's block id on success.

  done <block_id>
      Check the box and move it into the ✅ callout — sugar for
      `check <id>` followed by `checkmark move <id>`. Use after
      posting the done-comment so the completed item lands in the
      'done' callout in one step. Prints the new to_do's block id.

  iframe <page_id> <url>   (alias: embed)
      Append a Notion `embed` block (rendered as an iframe) to the
      given page with the given URL. Prints the new block id on
      success. Use this to programmatically drop iframes onto a page.

  title <page_id>
      Fetch the page and print its title on one line. Prints an empty
      line (exit 0) when the page has no title. Used by callers that
      want a human-readable label for a page id (e.g. browser tab
      titles) without parsing the full markdown render.

  comments <block_or_page_id> [--json]
      List comments attached to a block or page. Notion's comments
      API is keyed by block_id but a page id (the page's own block
      id) also works. Default output: one comment per line in the
      form \"<created_time> [<author>] <text>\" where <author> is
      the display_name if resolved, else a short user id. With
      --json: pretty-printed raw JSON (the \"results\" array from
      the Notion API). Prints an empty result (exit 0, no lines)
      if there are no comments. Use this to read replies to your
      own progress/blocker comments so an agent can close the loop
      without restarting.

AGENT WORKFLOW
  1. notion_cli fetch <page_id> --empress-only -o page.md
  2. Read page.md. For any to_do line \"- [ ] ...\", the preceding
     line \"[//]: # (notion_block_id: <ID>)\" gives the block id.
     Grep: grep -B1 '^- \\[ \\]' page.md
  3. notion_cli comment --block <ID> \"Done: <what changed>\"
  4. notion_cli done <ID>   (checks the box + moves it into the ✅ callout)

IDS
  Notion accepts either dashed UUIDs
  (1f9e6c34-1234-4abc-9ff0-0c52e8e3c111) or the 32-hex form without
  dashes. Both work here.

ENV
  NOTION_TOKEN        required. Notion integration token
                      (Bearer). Create one at
                      https://www.notion.so/profile/integrations and
                      share the page/database with the integration.
  NOTION_PAGE_ID      optional. Fallback for fetch when no
                      positional page_id is given.
  NOTION_API_VERSION  optional. Override the Notion-Version header
                      (default 2022-06-28).

EXIT CODES
  0  success
  1  API, network, or decode error; block is not to_do; write failed
  (any other)  unrecognised arguments (usage printed)

EXAMPLES
  export NOTION_TOKEN=secret_…
  notion_cli fetch 1f9e6c34123440bc9ff00c52e8e3c111 -o page.md
  notion_cli check 1f9e6c34-5678-4def-9ff0-0c52e8e3c222
  notion_cli check 1f9e6c34-5678-4def-9ff0-0c52e8e3c222 --uncheck
  notion_cli comment --block 1f9e6c34-5678-4def-9ff0-0c52e8e3c222 hi
  notion_cli comments 1f9e6c34-5678-4def-9ff0-0c52e8e3c222
  notion_cli comments 1f9e6c34-5678-4def-9ff0-0c52e8e3c222 --json

SCOPE
  Only to_do blocks are supported for check. Database-row checkbox
  properties use a different API and are not handled here. For
  append / update / create, use the notion_client CLI.",
  )
}

fn cmd_fetch_env(out: Option(String), empress_only: Bool) -> Nil {
  case envoy.get("NOTION_PAGE_ID") {
    Ok(id) -> cmd_fetch(id, out, empress_only)
    Error(_) ->
      die(
        "fetch: page_id missing — pass as argument or set NOTION_PAGE_ID",
      )
  }
}

// ─── fetch ──────────────────────────────────────────────────────────────

fn cmd_fetch(page_id: String, out: Option(String), empress_only: Bool) -> Nil {
  case with_client(fn(c) { do_fetch(c, page_id, empress_only) }) {
    Error(msg) -> die(msg)
    Ok(md) ->
      case out {
        None -> io.println(md)
        Some(path) ->
          case simplifile.write(path, md) {
            Ok(_) -> io.println(path)
            Error(e) -> die("write failed: " <> simplifile.describe_error(e))
          }
      }
  }
}

fn do_fetch(
  client: Client,
  page_id: String,
  empress_only: Bool,
) -> Result(String, String) {
  use page <- result.try(get_json(client, "/v1/pages/" <> page_id))
  let title =
    decode.run(page, title_decoder())
    |> result.unwrap("untitled")
  use tree <- result.try(fetch_annotated(client, page_id, empress_only))
  let body = markdown.to_markdown_annotated(tree)
  Ok("# " <> title <> "\n\n" <> body <> "\n")
}

fn fetch_annotated(
  client: Client,
  parent_id: String,
  empress_only: Bool,
) -> Result(List(AnnotatedBlock), String) {
  use entries <- result.try(fetch_children(client, parent_id))
  list.try_map(entries, fn(entry) {
    let #(raw, block, id, has_children) = entry
    case block {
      markdown.Table(_, _, _) ->
        case has_children {
          False -> Ok(AnnotatedBlock(id, block, []))
          True -> {
            use rows <- result.try(fetch_children(client, id))
            let row_blocks = list.map(rows, fn(r) { r.1 })
            Ok(AnnotatedBlock(id, markdown.with_children(block, row_blocks), []))
          }
        }
      markdown.ChildPage(_, _, _, _, _) -> Ok(AnnotatedBlock(id, block, []))
      markdown.ChildDatabase(_, _) -> Ok(AnnotatedBlock(id, block, []))
      markdown.SyncedBlock(_, _, _, _) -> Ok(AnnotatedBlock(id, block, []))
      _ ->
        case has_children, empress_only && is_checkmark_callout_raw(raw) {
          _, True -> Ok(AnnotatedBlock(id, block, []))
          False, _ -> Ok(AnnotatedBlock(id, block, []))
          True, False -> {
            use kids <- result.try(fetch_annotated(client, id, empress_only))
            Ok(AnnotatedBlock(id, block, kids))
          }
        }
    }
  })
}

fn is_checkmark_callout_raw(raw: Dynamic) -> Bool {
  case decode.run(raw, callout_id_if_emoji_decoder(checkmark_emoji_variants())) {
    Ok(Some(_)) -> True
    _ -> False
  }
}

fn fetch_children(
  client: Client,
  parent_id: String,
) -> Result(List(#(Dynamic, Block, String, Bool)), String) {
  use body <- result.try(get_json(
    client,
    "/v1/blocks/" <> parent_id <> "/children",
  ))
  decode.run(body, children_decoder())
  |> result.map_error(fn(_) { "decode children failed" })
}

fn children_decoder() -> decode.Decoder(List(#(Dynamic, Block, String, Bool))) {
  use results <- decode.field("results", decode.list(block_entry_decoder()))
  decode.success(results)
}

fn block_entry_decoder() -> decode.Decoder(#(Dynamic, Block, String, Bool)) {
  use raw <- decode.then(decode.dynamic)
  use b <- decode.then(markdown.block_decoder())
  use id <- decode.field("id", decode.string)
  use has_children <- decode.field("has_children", decode.optional(decode.bool))
  decode.success(#(raw, b, id, option.unwrap(has_children, False)))
}

// ─── check ──────────────────────────────────────────────────────────────

fn cmd_check(block_id: String, checked: Bool) -> Nil {
  case with_client(fn(c) { do_check(c, block_id, checked) }) {
    Ok(_) -> io.println("ok")
    Error(msg) -> die(msg)
  }
}

fn do_check(
  client: Client,
  block_id: String,
  checked: Bool,
) -> Result(Nil, String) {
  use block_json <- result.try(get_json(client, "/v1/blocks/" <> block_id))
  case decode.run(block_json, block_type_decoder()) {
    Ok("to_do") -> patch_checked(client, block_id, checked)
    Ok(other) ->
      Error("block " <> block_id <> " is type \"" <> other <> "\", not to_do")
    Error(_) -> Error("could not determine block type for " <> block_id)
  }
}

fn block_type_decoder() -> decode.Decoder(String) {
  use t <- decode.field("type", decode.string)
  decode.success(t)
}

fn patch_checked(
  client: Client,
  block_id: String,
  checked: Bool,
) -> Result(Nil, String) {
  let body =
    json.object([
      #("to_do", json.object([#("checked", json.bool(checked))])),
    ])
  let req =
    notion_client.base_request(client)
    |> request.set_method(http.Patch)
    |> request.set_path("/v1/blocks/" <> block_id)
    |> request.set_body(<<json.to_string(body):utf8>>)
  use _ <- result.try(send_json(client, req))
  Ok(Nil)
}

// ─── comment ───────────────────────────────────────────────────────────

fn cmd_comment(page_id: String, text: String) -> Nil {
  do_comment_cmd("page_id", page_id, text)
}

fn cmd_comment_block(block_id: String, text: String) -> Nil {
  do_comment_cmd("block_id", block_id, text)
}

fn do_comment_cmd(parent_key: String, parent_id: String, text: String) -> Nil {
  case string.trim(text) {
    "" -> die("comment: text is empty")
    t ->
      case with_client(fn(c) { do_comment(c, parent_key, parent_id, t) }) {
        Ok(_) -> io.println("ok")
        Error(msg) -> die(msg)
      }
  }
}

fn do_comment(
  client: Client,
  parent_key: String,
  parent_id: String,
  text: String,
) -> Result(Nil, String) {
  let body =
    json.object([
      #("parent", json.object([#(parent_key, json.string(parent_id))])),
      #(
        "rich_text",
        json.preprocessed_array([
          json.object([
            #("type", json.string("text")),
            #("text", json.object([#("content", json.string(text))])),
          ]),
        ]),
      ),
    ])
  let req =
    notion_client.base_request(client)
    |> request.set_method(http.Post)
    |> request.set_path("/v1/comments")
    |> request.set_body(<<json.to_string(body):utf8>>)
  use _ <- result.try(send_json(client, req))
  Ok(Nil)
}

// ─── comments (read) ───────────────────────────────────────────────────

type CommentRow {
  CommentRow(
    created_time: String,
    author: String,
    text: String,
  )
}

fn cmd_comments(id: String, json_out: Bool) -> Nil {
  case with_client(fn(c) { do_list_comments(c, id, json_out) }) {
    Error(msg) -> die(msg)
    Ok(output) ->
      case output {
        "" -> Nil
        s -> io.println(s)
      }
  }
}

fn do_list_comments(
  client: Client,
  id: String,
  json_out: Bool,
) -> Result(String, String) {
  let path = "/v1/comments?block_id=" <> id
  case json_out {
    True -> get_raw(client, path)
    False -> {
      use body <- result.try(get_json(client, path))
      use rows <- result.try(
        decode.run(body, comment_rows_decoder())
        |> result.map_error(fn(_) { "decode comments failed" }),
      )
      Ok(
        rows
        |> list.map(format_comment_row)
        |> string.join("\n"),
      )
    }
  }
}

fn format_comment_row(r: CommentRow) -> String {
  r.created_time <> " [" <> r.author <> "] " <> r.text
}

fn comment_rows_decoder() -> decode.Decoder(List(CommentRow)) {
  use results <- decode.field("results", decode.list(comment_row_decoder()))
  decode.success(results)
}

fn comment_row_decoder() -> decode.Decoder(CommentRow) {
  use created_time <- decode.field("created_time", decode.string)
  use rich_text <- decode.field(
    "rich_text",
    decode.list(plain_text_decoder()),
  )
  use author <- decode.then(author_decoder())
  decode.success(CommentRow(
    created_time: created_time,
    author: author,
    text: string.join(rich_text, ""),
  ))
}

fn author_decoder() -> decode.Decoder(String) {
  use display <- decode.optional_field(
    "display_name",
    None,
    display_name_resolved_decoder(),
  )
  case display {
    Some(name) -> decode.success(name)
    None -> {
      use user_id <- decode.subfield(
        ["created_by", "id"],
        decode.optional(decode.string),
      )
      decode.success(short_user_id(option.unwrap(user_id, "unknown")))
    }
  }
}

fn display_name_resolved_decoder() -> decode.Decoder(Option(String)) {
  use resolved <- decode.optional_field(
    "resolved_name",
    None,
    decode.optional(decode.string),
  )
  decode.success(resolved)
}

fn short_user_id(id: String) -> String {
  // Collapse "3425cbd3-c0c6-81d1-af1a-002788643e95" -> "3425cbd3".
  case string.split_once(id, "-") {
    Ok(#(prefix, _)) -> prefix
    Error(_) ->
      case string.length(id) > 8 {
        True -> string.slice(id, 0, 8)
        False -> id
      }
  }
}

// ─── princess (callout discovery) ──────────────────────────────────────
//
// Convention used by empress: each Notion page has an "empress
// instructions" callout block with the princess emoji (👸). Its
// to_do children are the project's open tasks. This command locates
// that callout + collects its open todos so empress (and any other
// caller) can show a todo list without re-implementing the API walk.

const princess_emoji: String = "👸"

const checkmark_emoji: String = "✅"

fn princess_emoji_variants() -> List(String) {
  [princess_emoji, "👸🏻", "👸🏼", "👸🏽", "👸🏾", "👸🏿"]
}

fn checkmark_emoji_variants() -> List(String) {
  [checkmark_emoji, "☑️", "☑", "✔️", "✔"]
}

type PrincessTodo {
  PrincessTodo(id: String, text: String, checked: Bool, depth: Int)
}

type PrincessResult {
  PrincessFound(
    callout_id: String,
    todos: List(PrincessTodo),
    content_markdown: String,
  )
  PrincessMissing
}

fn cmd_princess(page_id: String, json_out: Bool, include_checked: Bool) -> Nil {
  case with_client(fn(c) { do_find_princess(c, page_id, include_checked) }) {
    Error(msg) -> die(msg)
    Ok(result) ->
      case json_out {
        True -> io.println(princess_to_json(result))
        False -> io.println(princess_to_text(result))
      }
  }
}

fn do_find_princess(
  client: Client,
  page_id: String,
  include_checked: Bool,
) -> Result(PrincessResult, String) {
  use children <- result.try(list_children_raw(client, page_id))
  case find_princess_callout(children) {
    None -> Ok(PrincessMissing)
    Some(#(callout_id, header_text)) -> {
      use todo_children <- result.try(list_children_raw(client, callout_id))
      use todos <- result.try(collect_todos_recursive(
        client,
        todo_children,
        0,
        include_checked,
      ))
      // Render the callout's non-todo content as markdown so callers
      // (empress → "Let's rule" prompt) see workflow notes + specific
      // instructions that live alongside the todo list. Included:
      //   - the callout's own rich_text header (e.g. "DO NOT KILL THE
      //     empress_cli process") — prepended at the top
      //   - every top-level child block that is NOT a `to_do`
      //     (paragraphs, bullets, headings, code, etc.)
      // Excluded: `to_do` children (already carried structured in
      // `todos`) and per-todo nested children (subagents fetch those
      // via `notion_cli fetch` when they pick up a todo).
      use annotated <- result.try(fetch_annotated(client, callout_id, False))
      let body =
        annotated
        |> list.filter(fn(ab) { !is_todo_block(ab.block) })
        |> render_callout_body
      let content_markdown = case string.trim(header_text), string.trim(body) {
        "", b -> b
        h, "" -> h
        h, b -> h <> "\n\n" <> b
      }
      Ok(PrincessFound(callout_id, todos, content_markdown))
    }
  }
}

fn is_todo_block(b: Block) -> Bool {
  case b {
    markdown.ToDo(_, _) -> True
    _ -> False
  }
}

/// Render the callout's body blocks for human display + the empress
/// "Let's rule" prompt. Each block becomes its own markdown paragraph
/// separated by a blank line so consecutive paragraphs stay visually
/// distinct and shift-enter `\n` line breaks inside a paragraph
/// survive. We deliberately drop the block_id `[//]: # (...)` comments
/// `to_markdown_annotated` would emit — the callout body is read by
/// humans and fed verbatim to Claude, neither of which needs the
/// per-block grep handle.
fn render_callout_body(blocks: List(AnnotatedBlock)) -> String {
  blocks
  |> list.map(fn(ab) { markdown.to_markdown([ab.block]) })
  |> list.filter(fn(s) { string.trim(s) != "" })
  |> string.join("\n\n")
}

/// Return the raw list of child block JSON under a parent. We use the
/// undecoded dynamics here because markdown.block_decoder() doesn't
/// preserve `callout` typing (it falls through to Unsupported and loses
/// the icon/emoji — which we need).
fn list_children_raw(
  client: Client,
  parent_id: String,
) -> Result(List(Dynamic), String) {
  use body <- result.try(get_json(
    client,
    "/v1/blocks/" <> parent_id <> "/children",
  ))
  let dec = {
    use items <- decode.field("results", decode.list(decode.dynamic))
    decode.success(items)
  }
  decode.run(body, dec)
  |> result.map_error(fn(_) { "decode children failed" })
}

fn find_princess_callout(children: List(Dynamic)) -> Option(#(String, String)) {
  list.find_map(children, fn(block) {
    case decode.run(block, princess_identity_decoder()) {
      Ok(Some(pair)) -> Ok(pair)
      _ -> Error(Nil)
    }
  })
  |> option_from_result
}

fn princess_identity_decoder() -> decode.Decoder(Option(#(String, String))) {
  use type_ <- decode.field("type", decode.string)
  case type_ {
    "callout" -> {
      use emoji <- decode.optional_field(
        "callout",
        None,
        callout_emoji_decoder(),
      )
      case emoji {
        Some(e) if e == princess_emoji
          || e == "👸🏻"
          || e == "👸🏼"
          || e == "👸🏽"
          || e == "👸🏾"
          || e == "👸🏿" -> {
          use id <- decode.field("id", decode.string)
          use header <- decode.subfield(
            ["callout", "rich_text"],
            decode.list(plain_text_decoder()),
          )
          decode.success(Some(#(id, string.join(header, ""))))
        }
        _ -> decode.success(None)
      }
    }
    _ -> decode.success(None)
  }
}

/// Decode a `callout` object's `{icon: {type: "emoji", emoji: "👸"}}`
/// path into `Some("👸")`, returning `None` if the icon is missing or
/// isn't an emoji.
fn callout_emoji_decoder() -> decode.Decoder(Option(String)) {
  let emoji_dec = {
    use e <- decode.field("emoji", decode.string)
    decode.success(Some(e))
  }
  {
    use emoji <- decode.optional_field("icon", None, emoji_dec)
    decode.success(emoji)
  }
}

/// Walk the block tree rooted at `children` and collect every open
/// `to_do` block into a flat list — top-level todos first, then any
/// nested sub-todos in document order. Notion's children.list endpoint
/// only returns direct children; any block with `has_children: true`
/// requires a follow-up fetch. Without this recursion, todos nested
/// under another todo (or under any non-todo block like a toggle / bullet)
/// would be silently dropped from the princess list.
///
/// Traversal is depth-first and does NOT fetch children of the callout-
/// container itself (the caller already supplies those); it only recurses
/// into sub-children as discovered. Parent checked-state is ignored: a
/// checked parent may still carry open sub-todos, which we do want to
/// surface.
fn collect_todos_recursive(
  client: Client,
  children: List(Dynamic),
  depth: Int,
  include_checked: Bool,
) -> Result(List(PrincessTodo), String) {
  list.try_fold(children, [], fn(acc, block) {
    let matched = case decode.run(block, todo_decoder(depth, include_checked)) {
      Ok(Some(t)) -> Some(t)
      _ -> None
    }
    let this = case matched {
      Some(t) -> [t]
      None -> []
    }
    // A nested to_do is one level deeper than its parent. For
    // non-to_do containers (toggles, bullets, callouts) we keep depth
    // the same. When surfacing checked todos too, bumping depth for
    // any to_do parent (open OR checked) keeps the visual hierarchy
    // consistent.
    let next_depth = case decode.run(block, block_type_decoder()) {
      Ok("to_do") -> depth + 1
      _ -> depth
    }
    case decode.run(block, block_id_and_children_decoder()) {
      Ok(#(id, True)) -> {
        use sub <- result.try(list_children_raw(client, id))
        use nested <- result.try(collect_todos_recursive(
          client,
          sub,
          next_depth,
          include_checked,
        ))
        Ok(list.flatten([acc, this, nested]))
      }
      _ -> Ok(list.flatten([acc, this]))
    }
  })
}

fn block_id_and_children_decoder() -> decode.Decoder(#(String, Bool)) {
  use id <- decode.field("id", decode.string)
  use has_children <- decode.optional_field(
    "has_children",
    False,
    decode.bool,
  )
  decode.success(#(id, has_children))
}

fn todo_decoder(
  depth: Int,
  include_checked: Bool,
) -> decode.Decoder(Option(PrincessTodo)) {
  use type_ <- decode.field("type", decode.string)
  case type_ {
    "to_do" -> {
      use id <- decode.field("id", decode.string)
      use text <- decode.subfield(
        ["to_do", "rich_text"],
        decode.list(plain_text_decoder()),
      )
      use checked <- decode.subfield(
        ["to_do", "checked"],
        decode.optional(decode.bool),
      )
      let c = option.unwrap(checked, False)
      case c, include_checked {
        True, False -> decode.success(None)
        _, _ ->
          decode.success(Some(PrincessTodo(
            id: id,
            text: string.join(text, ""),
            checked: c,
            depth: depth,
          )))
      }
    }
    _ -> decode.success(None)
  }
}

fn option_from_result(r: Result(a, Nil)) -> Option(a) {
  case r {
    Ok(v) -> Some(v)
    Error(_) -> None
  }
}

fn princess_to_json(r: PrincessResult) -> String {
  case r {
    PrincessMissing ->
      json.to_string(
        json.object([#("status", json.string("missing"))]),
      )
    PrincessFound(callout_id, todos, content_markdown) ->
      json.to_string(
        json.object([
          #("status", json.string("found")),
          #("callout_block_id", json.string(callout_id)),
          #(
            "todos",
            json.preprocessed_array(
              list.map(todos, fn(t) {
                json.object([
                  #("id", json.string(t.id)),
                  #("text", json.string(t.text)),
                  #("checked", json.bool(t.checked)),
                  #("depth", json.int(t.depth)),
                ])
              }),
            ),
          ),
          #("content_markdown", json.string(content_markdown)),
        ]),
      )
  }
}

fn princess_to_text(r: PrincessResult) -> String {
  case r {
    PrincessMissing -> "missing"
    PrincessFound(callout_id, todos, content_markdown) -> {
      let header = "found " <> callout_id
      let todo_section = case todos {
        [] -> "(no open todos)"
        _ ->
          string.join(
            list.map(todos, fn(t) {
              let box = case t.checked {
                True -> "- [x] "
                False -> "- [ ] "
              }
              string.repeat("  ", t.depth) <> box <> t.id <> " " <> t.text
            }),
            "\n",
          )
      }
      let content_section = case string.trim(content_markdown) {
        "" -> ""
        trimmed -> "\n---\n" <> trimmed
      }
      header <> "\n" <> todo_section <> content_section
    }
  }
}

// Create a princess callout as the FIRST child of the page (prepend),
// so it's visible at the top. Notion's `children.patch` endpoint
// supports an `after` field to insert in the middle; to put a block
// first we use `after = (first existing child id)` — wait, `after`
// puts the new block AFTER that id. To prepend we instead need to
// provide `after` referring to… actually Notion's API appends at the
// end by default. To truly prepend, we must re-parent the existing
// children — a heavy operation we avoid. Acceptable compromise:
// the callout is appended to the existing children (so it lands as
// the LAST first-level block on the page); users wanting it at the
// very top can drag it in Notion. Document this in the help text.
fn cmd_princess_create(page_id: String) -> Nil {
  case with_client(fn(c) { do_create_princess(c, page_id) }) {
    Error(msg) -> die(msg)
    Ok(id) -> io.println(id)
  }
}

fn do_create_princess(
  client: Client,
  page_id: String,
) -> Result(String, String) {
  // Seed a single example to_do so a freshly-created empress block is
  // never an empty callout — the first thing the user sees is a
  // concrete, editable item they can replace with their real request.
  let example_todo =
    json.object([
      #("object", json.string("block")),
      #("type", json.string("to_do")),
      #(
        "to_do",
        json.object([
          #(
            "rich_text",
            json.preprocessed_array([
              json.object([
                #("type", json.string("text")),
                #(
                  "text",
                  json.object([
                    #(
                      "content",
                      json.string(
                        "example todo — replace with what you want empress to do",
                      ),
                    ),
                  ]),
                ),
              ]),
            ]),
          ),
          #("checked", json.bool(False)),
        ]),
      ),
    ])
  let callout_block =
    json.object([
      #("object", json.string("block")),
      #("type", json.string("callout")),
      #(
        "callout",
        json.object([
          #(
            "rich_text",
            json.preprocessed_array([
              json.object([
                #("type", json.string("text")),
                #(
                  "text",
                  json.object([
                    #(
                      "content",
                      json.string("empress instructions — add todos below"),
                    ),
                  ]),
                ),
              ]),
            ]),
          ),
          #(
            "icon",
            json.object([
              #("type", json.string("emoji")),
              #("emoji", json.string(princess_emoji)),
            ]),
          ),
          #("color", json.string("gray_background")),
          #("children", json.preprocessed_array([example_todo])),
        ]),
      ),
    ])
  // Fetch existing first child (if any) so we can pass `after=<first>`
  // — but `after` on PATCH children appends after that id. To put the
  // new callout BEFORE the first existing child we'd need a re-order
  // pass. We accept "appended at the end" as the pragmatic default;
  // the user can drag it up in Notion. The todo asks for "first child"
  // — we emit a hint to stderr so the caller knows.
  let body =
    json.object([
      #("children", json.preprocessed_array([callout_block])),
    ])
  let req =
    notion_client.base_request(client)
    |> request.set_method(http.Patch)
    |> request.set_path("/v1/blocks/" <> page_id <> "/children")
    |> request.set_body(<<json.to_string(body):utf8>>)
  use resp <- result.try(send_json(client, req))
  case decode.run(resp, created_block_id_decoder()) {
    Ok(id) -> Ok(id)
    Error(_) -> Error("could not read new callout id from response")
  }
}

// ─── checkmark (done-tasks callout) ────────────────────────────────────
//
// Convention: each Notion page can carry a ✅ callout as a sibling to
// the 👸 empress callout. Completed empress todos get moved here via
// `checkmark move` so the empress callout stays focused on open work
// while completed items live in a scannable "done" list on the same
// page.

fn cmd_checkmark_ensure(page_id: String) -> Nil {
  case with_client(fn(c) { ensure_checkmark(c, page_id) }) {
    Ok(id) -> io.println(id)
    Error(msg) -> die(msg)
  }
}

fn ensure_checkmark(client: Client, page_id: String) -> Result(String, String) {
  use children <- result.try(list_children_raw(client, page_id))
  case find_callout_id_by_emoji(children, checkmark_emoji_variants()) {
    Some(id) -> Ok(id)
    None -> {
      let after = find_callout_id_by_emoji(children, princess_emoji_variants())
      create_checkmark(client, page_id, after)
    }
  }
}

fn find_callout_id_by_emoji(
  children: List(Dynamic),
  emojis: List(String),
) -> Option(String) {
  list.find_map(children, fn(block) {
    case decode.run(block, callout_id_if_emoji_decoder(emojis)) {
      Ok(Some(id)) -> Ok(id)
      _ -> Error(Nil)
    }
  })
  |> option_from_result
}

fn callout_id_if_emoji_decoder(
  emojis: List(String),
) -> decode.Decoder(Option(String)) {
  use type_ <- decode.field("type", decode.string)
  case type_ {
    "callout" -> {
      use emoji <- decode.optional_field(
        "callout",
        None,
        callout_emoji_decoder(),
      )
      case emoji {
        Some(e) ->
          case list.contains(emojis, e) {
            True -> {
              use id <- decode.field("id", decode.string)
              decode.success(Some(id))
            }
            False -> decode.success(None)
          }
        None -> decode.success(None)
      }
    }
    _ -> decode.success(None)
  }
}

fn create_checkmark(
  client: Client,
  page_id: String,
  after: Option(String),
) -> Result(String, String) {
  let callout_block =
    json.object([
      #("object", json.string("block")),
      #("type", json.string("callout")),
      #(
        "callout",
        json.object([
          #(
            "rich_text",
            json.preprocessed_array([
              json.object([
                #("type", json.string("text")),
                #(
                  "text",
                  json.object([#("content", json.string("done"))]),
                ),
              ]),
            ]),
          ),
          #(
            "icon",
            json.object([
              #("type", json.string("emoji")),
              #("emoji", json.string(checkmark_emoji)),
            ]),
          ),
          #("color", json.string("green_background")),
        ]),
      ),
    ])
  let base_fields = [
    #("children", json.preprocessed_array([callout_block])),
  ]
  let body_fields = case after {
    Some(sib_id) -> [#("after", json.string(sib_id)), ..base_fields]
    None -> base_fields
  }
  let req =
    notion_client.base_request(client)
    |> request.set_method(http.Patch)
    |> request.set_path("/v1/blocks/" <> page_id <> "/children")
    |> request.set_body(<<json.to_string(json.object(body_fields)):utf8>>)
  use resp <- result.try(send_json(client, req))
  case decode.run(resp, created_block_id_decoder()) {
    Ok(id) -> Ok(id)
    Error(_) -> Error("could not read new callout id from response")
  }
}

fn cmd_checkmark_move(block_id: String) -> Nil {
  case with_client(fn(c) { move_to_checkmark(c, block_id) }) {
    Ok(id) -> io.println(id)
    Error(msg) -> die(msg)
  }
}

fn cmd_done(block_id: String) -> Nil {
  case with_client(fn(c) { do_done(c, block_id) }) {
    Ok(id) -> io.println(id)
    Error(msg) -> die(msg)
  }
}

fn do_done(client: Client, block_id: String) -> Result(String, String) {
  use _ <- result.try(do_check(client, block_id, True))
  move_to_checkmark(client, block_id)
}

fn move_to_checkmark(client: Client, block_id: String) -> Result(String, String) {
  use block_json <- result.try(get_json(client, "/v1/blocks/" <> block_id))
  use _ <- result.try(case decode.run(block_json, block_type_decoder()) {
    Ok("to_do") -> Ok(Nil)
    Ok(other) ->
      Error("block " <> block_id <> " is type \"" <> other <> "\", not to_do")
    Error(_) -> Error("could not determine block type for " <> block_id)
  })
  use page_id <- result.try(resolve_page_id(client, block_json, block_id))
  use text <- result.try(
    decode.run(block_json, todo_text_decoder())
    |> result.map_error(fn(_) { "could not read to_do text for " <> block_id }),
  )
  use checkmark_id <- result.try(ensure_checkmark(client, page_id))
  use new_id <- result.try(append_done_todo(client, checkmark_id, text))
  use _ <- result.try(archive_block(client, block_id))
  Ok(new_id)
}

/// Walk parent pointers from `block_json` up to the first page-typed
/// parent so `checkmark move` can be called with any todo id, whether
/// it's a direct child of the page or nested under the empress callout
/// (or arbitrarily deeper). The Notion `parent` field on a block is
/// either `{type: "page_id", page_id}`, `{type: "block_id", block_id}`,
/// or (rare here) a workspace / database parent — the last two get an
/// explicit error so the caller sees why the move can't complete.
fn resolve_page_id(
  client: Client,
  block_json: Dynamic,
  starting_id: String,
) -> Result(String, String) {
  case decode.run(block_json, parent_ref_decoder()) {
    Ok(PageParent(page_id)) -> Ok(page_id)
    Ok(BlockParent(next_id)) -> {
      use next_json <- result.try(get_json(client, "/v1/blocks/" <> next_id))
      resolve_page_id(client, next_json, starting_id)
    }
    Ok(OtherParent(kind)) ->
      Error(
        "block "
        <> starting_id
        <> " ultimately parents into a "
        <> kind
        <> " — checkmark move only supports blocks under a page",
      )
    Error(_) ->
      Error("could not read parent for block " <> starting_id)
  }
}

type ParentRef {
  PageParent(page_id: String)
  BlockParent(block_id: String)
  OtherParent(kind: String)
}

fn parent_ref_decoder() -> decode.Decoder(ParentRef) {
  use type_ <- decode.subfield(["parent", "type"], decode.string)
  case type_ {
    "page_id" -> {
      use id <- decode.subfield(["parent", "page_id"], decode.string)
      decode.success(PageParent(id))
    }
    "block_id" -> {
      use id <- decode.subfield(["parent", "block_id"], decode.string)
      decode.success(BlockParent(id))
    }
    other -> decode.success(OtherParent(other))
  }
}

fn todo_text_decoder() -> decode.Decoder(String) {
  use rt <- decode.subfield(
    ["to_do", "rich_text"],
    decode.list(plain_text_decoder()),
  )
  decode.success(string.join(rt, ""))
}

fn append_done_todo(
  client: Client,
  parent_id: String,
  text: String,
) -> Result(String, String) {
  let todo_block =
    json.object([
      #("object", json.string("block")),
      #("type", json.string("to_do")),
      #(
        "to_do",
        json.object([
          #(
            "rich_text",
            json.preprocessed_array([
              json.object([
                #("type", json.string("text")),
                #(
                  "text",
                  json.object([#("content", json.string(text))]),
                ),
              ]),
            ]),
          ),
          #("checked", json.bool(True)),
        ]),
      ),
    ])
  let body =
    json.object([
      #("children", json.preprocessed_array([todo_block])),
    ])
  let req =
    notion_client.base_request(client)
    |> request.set_method(http.Patch)
    |> request.set_path("/v1/blocks/" <> parent_id <> "/children")
    |> request.set_body(<<json.to_string(body):utf8>>)
  use resp <- result.try(send_json(client, req))
  case decode.run(resp, created_block_id_decoder()) {
    Ok(id) -> Ok(id)
    Error(_) -> Error("could not read new to_do id from response")
  }
}

fn archive_block(client: Client, block_id: String) -> Result(Nil, String) {
  let req =
    notion_client.base_request(client)
    |> request.set_method(http.Delete)
    |> request.set_path("/v1/blocks/" <> block_id)
  use _ <- result.try(send_json(client, req))
  Ok(Nil)
}

// ─── iframe (embed block append) ───────────────────────────────────────
//
// Append a Notion `embed` block with a given URL to a page (or any
// block that accepts children). Notion renders embeds as inline
// iframes; this is what you want for "create iframes in notion pages".

fn cmd_iframe(page_id: String, url: String) -> Nil {
  case string.trim(url) {
    "" -> die("iframe: url is empty")
    u ->
      case with_client(fn(c) { do_create_iframe(c, page_id, u) }) {
        Error(msg) -> die(msg)
        Ok(id) -> io.println(id)
      }
  }
}

fn do_create_iframe(
  client: Client,
  page_id: String,
  url: String,
) -> Result(String, String) {
  let embed_block =
    json.object([
      #("object", json.string("block")),
      #("type", json.string("embed")),
      #("embed", json.object([#("url", json.string(url))])),
    ])
  let body =
    json.object([
      #("children", json.preprocessed_array([embed_block])),
    ])
  let req =
    notion_client.base_request(client)
    |> request.set_method(http.Patch)
    |> request.set_path("/v1/blocks/" <> page_id <> "/children")
    |> request.set_body(<<json.to_string(body):utf8>>)
  use resp <- result.try(send_json(client, req))
  case decode.run(resp, created_block_id_decoder()) {
    Ok(id) -> Ok(id)
    Error(_) -> Error("could not read new embed block id from response")
  }
}

fn created_block_id_decoder() -> decode.Decoder(String) {
  use results <- decode.field(
    "results",
    decode.list({
      use id <- decode.field("id", decode.string)
      decode.success(id)
    }),
  )
  case results {
    [first, ..] -> decode.success(first)
    [] -> decode.failure("", "no created block")
  }
}

// ─── title (page title lookup) ─────────────────────────────────────────
//
// `notion_cli title <page_id>` — fetch a page and print its title on
// one line of stdout. Used by empress (notion_harness.fetch_page_title)
// to put the linked page name in the browser tab. Prints an empty line
// (and exits 0) when the page exists but has no title; dies on an API
// or decode failure so the caller can fall back to a path-based title.
fn cmd_title(page_id: String) -> Nil {
  case with_client(fn(c) { do_title(c, page_id) }) {
    Ok(t) -> io.println(t)
    Error(msg) -> die(msg)
  }
}

fn do_title(client: Client, page_id: String) -> Result(String, String) {
  use page <- result.try(get_json(client, "/v1/pages/" <> page_id))
  case decode.run(page, title_decoder()) {
    Ok("untitled") -> Ok("")
    Ok(t) -> Ok(t)
    Error(_) -> Ok("")
  }
}

// ─── page title decoder ────────────────────────────────────────────────

fn title_decoder() -> decode.Decoder(String) {
  use props <- decode.field(
    "properties",
    decode.dict(decode.string, title_property_decoder()),
  )
  let text =
    dict.values(props)
    |> list.find_map(fn(v) {
      case v {
        Some(s) -> Ok(s)
        None -> Error(Nil)
      }
    })
    |> result.unwrap("untitled")
  decode.success(text)
}

fn title_property_decoder() -> decode.Decoder(Option(String)) {
  use type_ <- decode.field("type", decode.string)
  case type_ {
    "title" -> {
      use rt <- decode.field("title", decode.list(plain_text_decoder()))
      decode.success(Some(string.join(rt, "")))
    }
    _ -> decode.success(None)
  }
}

fn plain_text_decoder() -> decode.Decoder(String) {
  use t <- decode.field("plain_text", decode.optional(decode.string))
  decode.success(option.unwrap(t, ""))
}

// ─── transport ─────────────────────────────────────────────────────────

fn get_json(client: Client, path: String) -> Result(Dynamic, String) {
  let req =
    notion_client.base_request(client)
    |> request.set_method(http.Get)
    |> request.set_path(path)
  send_json(client, req)
}

fn send_json(
  client: Client,
  req: request.Request(BitArray),
) -> Result(Dynamic, String) {
  case notion_client.request(client, req) {
    Error(e) -> Error(error_to_string(e))
    Ok(resp) ->
      case json.parse_bits(resp.body, decode.dynamic) {
        Ok(d) -> Ok(d)
        Error(_) -> Error("invalid json response")
      }
  }
}

fn get_raw(client: Client, path: String) -> Result(String, String) {
  let req =
    notion_client.base_request(client)
    |> request.set_method(http.Get)
    |> request.set_path(path)
  case notion_client.request(client, req) {
    Error(e) -> Error(error_to_string(e))
    Ok(resp) ->
      case bit_array.to_string(resp.body) {
        Ok(s) -> Ok(s)
        Error(_) -> Error("response not valid utf-8")
      }
  }
}

fn error_to_string(e: NotionError) -> String {
  case e {
    error.ApiResponseError(code: _, status: s, message: m) ->
      "api " <> string.inspect(s) <> ": " <> m
    error.ClientError(code: _) -> "client error"
  }
}

// ─── env + util ────────────────────────────────────────────────────────

fn with_client(run: fn(Client) -> Result(a, String)) -> Result(a, String) {
  use token <- result.try(
    envoy.get("NOTION_TOKEN")
    |> result.replace_error("NOTION_TOKEN not set"),
  )
  let base = notion_client.new(token)
  let client = case envoy.get("NOTION_API_VERSION") {
    Ok(v) -> notion_client.Client(..base, notion_version: v)
    Error(_) -> base
  }
  run(client)
}

fn die(msg: String) -> Nil {
  io.println_error("error: " <> msg)
  halt(1)
}

@external(erlang, "erlang", "halt")
fn halt(code: Int) -> Nil

// ─── .env loader ───────────────────────────────────────────────────────

fn load_dotenv() -> Nil {
  case simplifile.read(".env") {
    Error(_) -> Nil
    Ok(contents) -> {
      contents
      |> string.split("\n")
      |> list.each(apply_dotenv_line)
    }
  }
}

fn apply_dotenv_line(line: String) -> Nil {
  let trimmed = string.trim(line)
  case trimmed {
    "" -> Nil
    "#" <> _ -> Nil
    _ ->
      case string.split_once(trimmed, "=") {
        Error(_) -> Nil
        Ok(#(raw_key, raw_val)) -> {
          let key =
            raw_key
            |> string.trim
            |> strip_prefix("export ")
          let val = raw_val |> string.trim |> strip_quotes
          case envoy.get(key) {
            Ok(_) -> Nil
            Error(_) -> envoy.set(key, val)
          }
        }
      }
  }
}

fn strip_prefix(s: String, p: String) -> String {
  case string.starts_with(s, p) {
    True -> string.slice(s, string.length(p), string.length(s))
    False -> s
  }
}

fn strip_quotes(s: String) -> String {
  let n = string.length(s)
  case n >= 2 {
    False -> s
    True -> {
      let first = string.slice(s, 0, 1)
      let last = string.slice(s, n - 1, 1)
      case first == "\"" && last == "\"", first == "'" && last == "'" {
        True, _ -> string.slice(s, 1, n - 2)
        _, True -> string.slice(s, 1, n - 2)
        _, _ -> s
      }
    }
  }
}

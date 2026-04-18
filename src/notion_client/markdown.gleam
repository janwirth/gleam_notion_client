//// Markdown ↔ Notion block conversion.
////
//// Scope (v2, phase 16):
//// - paragraph, heading_1/2/3, bulleted_list_item, numbered_list_item,
////   to_do, code, quote, divider
//// - Rich text annotations + links via `notion_client/rich_text`
////   (bold, italic, strikethrough, code, underline, colour spans).
////
//// Unsupported blocks render as `<!-- unsupported: <type> -->` on read
//// and unknown markdown lines fall through to paragraph on write.

import gleam/dynamic/decode.{type Decoder}
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/string
import notion_client/rich_text

// ─── Types ──────────────────────────────────────────────────────────────

pub type Block {
  Paragraph(text: String, children: List(Block))
  Heading1(text: String)
  Heading2(text: String)
  Heading3(text: String)
  BulletedListItem(text: String, children: List(Block))
  NumberedListItem(text: String, children: List(Block))
  ToDo(text: String, checked: Bool)
  Code(text: String, language: String)
  Quote(text: String)
  Divider
  Unsupported(kind: String)
}

// ─── Notion JSON → Block ────────────────────────────────────────────────

pub fn block_decoder() -> Decoder(Block) {
  use type_ <- decode.field("type", decode.string)
  case type_ {
    "paragraph" -> decode_text_block("paragraph", Paragraph(_, []))
    "heading_1" -> decode_text_block("heading_1", fn(t) { Heading1(t) })
    "heading_2" -> decode_text_block("heading_2", fn(t) { Heading2(t) })
    "heading_3" -> decode_text_block("heading_3", fn(t) { Heading3(t) })
    "bulleted_list_item" ->
      decode_text_block("bulleted_list_item", BulletedListItem(_, []))
    "numbered_list_item" ->
      decode_text_block("numbered_list_item", NumberedListItem(_, []))
    "to_do" -> decode_todo()
    "code" -> decode_code()
    "quote" -> decode_text_block("quote", fn(t) { Quote(t) })
    "divider" -> decode.success(Divider)
    other -> decode.success(Unsupported(other))
  }
}

fn decode_text_block(key: String, wrap: fn(String) -> Block) -> Decoder(Block) {
  use text <- decode.subfield([key, "rich_text"], rich_text_markdown_decoder())
  decode.success(wrap(text))
}

fn decode_todo() -> Decoder(Block) {
  use text <- decode.subfield(
    ["to_do", "rich_text"],
    rich_text_markdown_decoder(),
  )
  use checked <- decode.subfield(
    ["to_do", "checked"],
    decode.optional(decode.bool),
  )
  decode.success(ToDo(text, option.unwrap(checked, False)))
}

fn decode_code() -> Decoder(Block) {
  use text <- decode.subfield(
    ["code", "rich_text"],
    plain_text_concat_decoder(),
  )
  use lang <- decode.subfield(
    ["code", "language"],
    decode.optional(decode.string),
  )
  decode.success(Code(text, option.unwrap(lang, "plain text")))
}

fn rich_text_markdown_decoder() -> Decoder(String) {
  rich_text.run_list_decoder()
  |> decode.map(rich_text.runs_to_markdown)
}

fn plain_text_concat_decoder() -> Decoder(String) {
  decode.list(plain_text_item_decoder())
  |> decode.map(string.join(_, ""))
}

fn plain_text_item_decoder() -> Decoder(String) {
  use plain <- decode.field("plain_text", decode.optional(decode.string))
  decode.success(option.unwrap(plain, ""))
}

// Attach children fetched separately (read side).
pub fn with_children(parent: Block, children: List(Block)) -> Block {
  case parent {
    Paragraph(t, _) -> Paragraph(t, children)
    BulletedListItem(t, _) -> BulletedListItem(t, children)
    NumberedListItem(t, _) -> NumberedListItem(t, children)
    other -> other
  }
}

// ─── Block → Markdown ──────────────────────────────────────────────────

pub fn to_markdown(blocks: List(Block)) -> String {
  render_blocks(blocks, 0, 1)
}

fn render_blocks(
  blocks: List(Block),
  indent: Int,
  _numbered_start: Int,
) -> String {
  render_numbered(blocks, indent, 1, "")
}

fn render_numbered(
  blocks: List(Block),
  indent: Int,
  n: Int,
  acc: String,
) -> String {
  case blocks {
    [] -> acc
    [b, ..rest] -> {
      let #(rendered, next_n) = render_block(b, indent, n)
      let sep = case acc {
        "" -> ""
        _ -> "\n"
      }
      render_numbered(rest, indent, next_n, acc <> sep <> rendered)
    }
  }
}

fn render_block(b: Block, indent: Int, n: Int) -> #(String, Int) {
  let pad = string.repeat("  ", indent)
  case b {
    Paragraph(t, children) -> #(
      pad <> t <> render_children(children, indent + 1),
      1,
    )
    Heading1(t) -> #(pad <> "# " <> t, 1)
    Heading2(t) -> #(pad <> "## " <> t, 1)
    Heading3(t) -> #(pad <> "### " <> t, 1)
    BulletedListItem(t, children) -> #(
      pad <> "- " <> t <> render_children(children, indent + 1),
      1,
    )
    NumberedListItem(t, children) -> #(
      pad
        <> int.to_string(n)
        <> ". "
        <> t
        <> render_children(children, indent + 1),
      n + 1,
    )
    ToDo(t, checked) -> {
      let box = case checked {
        True -> "[x]"
        False -> "[ ]"
      }
      #(pad <> "- " <> box <> " " <> t, 1)
    }
    Code(t, lang) -> #(
      pad <> "```" <> lang <> "\n" <> t <> "\n" <> pad <> "```",
      1,
    )
    Quote(t) -> #(pad <> "> " <> t, 1)
    Divider -> #(pad <> "---", 1)
    Unsupported(kind) -> #(pad <> "<!-- unsupported: " <> kind <> " -->", 1)
  }
}

fn render_children(children: List(Block), indent: Int) -> String {
  case children {
    [] -> ""
    _ -> "\n" <> render_blocks(children, indent, 1)
  }
}

// ─── Markdown → Notion JSON (for append) ───────────────────────────────

pub fn from_markdown(source: String) -> Json {
  let lines = string.split(source, "\n")
  let blocks = walk_lines(lines, [])
  json.object([#("children", json.array(blocks, fn(b) { b }))])
}

type ListItemKind {
  KBullet
  KNumbered
  KTodo(checked: Bool)
}

type LineClass {
  ClSkip
  ClListItem(level: Int, kind: ListItemKind, text: String)
  ClNonList(level: Int, json: Json)
}

fn walk_lines(lines: List(String), acc: List(Json)) -> List(Json) {
  case lines {
    [] -> list.reverse(acc)
    ["```" <> rest_first, ..rest] -> {
      let #(code, tail) = take_code_block(rest, [])
      let lang = case rest_first {
        "" -> "plain text"
        l -> l
      }
      walk_lines(tail, [code_block_json(code, lang), ..acc])
    }
    [line, ..rest] ->
      case classify_line(line) {
        ClSkip -> walk_lines(rest, acc)
        ClListItem(_, _, _) -> {
          let #(items, tail) = consume_list(lines, 0)
          walk_lines(tail, list.append(list.reverse(items), acc))
        }
        ClNonList(_, j) -> walk_lines(rest, [j, ..acc])
      }
  }
}

fn classify_line(line: String) -> LineClass {
  let indent_chars = count_indent(line)
  let content = string.trim(line)
  case content {
    "" -> ClSkip
    _ -> {
      let level = int.min(indent_chars / 2, 10)
      case list_kind(content) {
        Ok(#(kind, text)) -> ClListItem(level, kind, text)
        Error(_) -> ClNonList(level, non_list_block(content))
      }
    }
  }
}

fn count_indent(line: String) -> Int {
  case line {
    " " <> rest -> 1 + count_indent(rest)
    "\t" <> rest -> 4 + count_indent(rest)
    _ -> 0
  }
}

fn list_kind(content: String) -> Result(#(ListItemKind, String), Nil) {
  case content {
    "- [ ] " <> t -> Ok(#(KTodo(False), t))
    "- [x] " <> t -> Ok(#(KTodo(True), t))
    "- [X] " <> t -> Ok(#(KTodo(True), t))
    "- " <> t -> Ok(#(KBullet, t))
    "* " <> t -> Ok(#(KBullet, t))
    _ ->
      case parse_numbered(content) {
        Some(t) -> Ok(#(KNumbered, t))
        None -> Error(Nil)
      }
  }
}

fn non_list_block(content: String) -> Json {
  case content {
    "---" -> divider_json()
    "# " <> t -> heading_json(1, t)
    "## " <> t -> heading_json(2, t)
    "### " <> t -> heading_json(3, t)
    "> " <> t -> quote_json(t)
    _ -> paragraph_json(content)
  }
}

fn parse_numbered(line: String) -> Option(String) {
  case string.split_once(line, ". ") {
    Ok(#(prefix, rest)) ->
      case int.parse(prefix) {
        Ok(_) -> Some(rest)
        Error(_) -> None
      }
    Error(_) -> None
  }
}

type PendingItem {
  PendingItem(kind: ListItemKind, text: String, children: List(Json))
}

fn consume_list(lines: List(String), level: Int) -> #(List(Json), List(String)) {
  consume_list_loop(lines, level, [], None)
}

fn consume_list_loop(
  lines: List(String),
  level: Int,
  acc: List(Json),
  pending: Option(PendingItem),
) -> #(List(Json), List(String)) {
  case lines {
    [] -> #(list.reverse(finalize(acc, pending)), [])
    [line, ..rest] ->
      case classify_line(line) {
        ClSkip -> consume_list_loop(rest, level, acc, pending)
        ClListItem(item_level, kind, text) ->
          case int.compare(item_level, level) {
            order.Eq ->
              consume_list_loop(
                rest,
                level,
                finalize(acc, pending),
                Some(PendingItem(kind, text, [])),
              )
            order.Gt -> {
              let #(children, tail) = consume_list(lines, item_level)
              case pending {
                Some(p) ->
                  consume_list_loop(
                    tail,
                    level,
                    acc,
                    Some(PendingItem(
                      p.kind,
                      p.text,
                      list.append(p.children, children),
                    )),
                  )
                None ->
                  consume_list_loop(
                    tail,
                    level,
                    list.append(list.reverse(children), acc),
                    None,
                  )
              }
            }
            order.Lt -> #(list.reverse(finalize(acc, pending)), lines)
          }
        ClNonList(other_level, j) ->
          case other_level > level, pending {
            True, Some(p) ->
              consume_list_loop(
                rest,
                level,
                acc,
                Some(PendingItem(p.kind, p.text, list.append(p.children, [j]))),
              )
            _, _ -> #(list.reverse(finalize(acc, pending)), lines)
          }
      }
  }
}

fn finalize(acc: List(Json), pending: Option(PendingItem)) -> List(Json) {
  case pending {
    None -> acc
    Some(p) -> [list_item_json(p), ..acc]
  }
}

fn list_item_json(p: PendingItem) -> Json {
  case p.kind {
    KBullet -> nested_block_json("bulleted_list_item", p.text, p.children, None)
    KNumbered ->
      nested_block_json("numbered_list_item", p.text, p.children, None)
    KTodo(checked) ->
      nested_block_json("to_do", p.text, p.children, Some(checked))
  }
}

fn nested_block_json(
  kind: String,
  text: String,
  children: List(Json),
  checked: Option(Bool),
) -> Json {
  let base = [#("rich_text", rich_text_json(text))]
  let base = case checked {
    Some(b) -> list.append(base, [#("checked", json.bool(b))])
    None -> base
  }
  let fields = case children {
    [] -> base
    _ -> list.append(base, [#("children", json.array(children, fn(j) { j }))])
  }
  block_json(kind, json.object(fields))
}

fn take_code_block(
  lines: List(String),
  acc: List(String),
) -> #(String, List(String)) {
  case lines {
    [] -> #(string.join(list.reverse(acc), "\n"), [])
    ["```", ..rest] -> #(string.join(list.reverse(acc), "\n"), rest)
    ["```" <> _, ..rest] -> #(string.join(list.reverse(acc), "\n"), rest)
    [l, ..rest] -> take_code_block(rest, [l, ..acc])
  }
}

// ─── JSON constructors ─────────────────────────────────────────────────

fn rich_text_json(text: String) -> Json {
  rich_text.runs_to_json(rich_text.markdown_to_runs(text))
}

fn plain_rich_text_json(text: String) -> Json {
  json.array([text], fn(t) {
    json.object([
      #("type", json.string("text")),
      #("text", json.object([#("content", json.string(t))])),
    ])
  })
}

fn block_json(kind: String, inner: Json) -> Json {
  json.object([
    #("object", json.string("block")),
    #("type", json.string(kind)),
    #(kind, inner),
  ])
}

fn paragraph_json(text: String) -> Json {
  block_json("paragraph", json.object([#("rich_text", rich_text_json(text))]))
}

fn heading_json(level: Int, text: String) -> Json {
  let kind = "heading_" <> int.to_string(level)
  block_json(kind, json.object([#("rich_text", rich_text_json(text))]))
}

fn code_block_json(text: String, language: String) -> Json {
  block_json(
    "code",
    json.object([
      #("rich_text", plain_rich_text_json(text)),
      #("language", json.string(language)),
    ]),
  )
}

fn quote_json(text: String) -> Json {
  block_json("quote", json.object([#("rich_text", rich_text_json(text))]))
}

fn divider_json() -> Json {
  block_json("divider", json.object([]))
}

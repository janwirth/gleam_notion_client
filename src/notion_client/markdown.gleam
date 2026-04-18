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
import gleam/io
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
  Image(url: String, caption: String, external: Bool)
  Embed(url: String, caption: String)
  Bookmark(url: String)
  Table(rows: List(List(String)), has_column_header: Bool, has_row_header: Bool)
  TableRow(cells: List(String))
  ChildPage(
    id: String,
    title: String,
    depth: Int,
    children: List(Block),
    status: ChildPageStatus,
  )
  ChildDatabase(id: String, title: String)
  Unsupported(kind: String)
}

pub type ChildPageStatus {
  Inlined
  DepthLimitReached
  CycleDetected
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
    "image" -> decode_image()
    "embed" -> decode_embed()
    "bookmark" -> decode_bookmark("bookmark")
    "link_preview" -> decode_bookmark("link_preview")
    "table" -> decode_table()
    "table_row" -> decode_table_row()
    "child_page" -> decode_child_page()
    "child_database" -> decode_child_database()
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

fn decode_image() -> Decoder(Block) {
  let url_src_decoder =
    decode.one_of(
      decode.at(["external", "url"], decode.string)
        |> decode.map(fn(u) { #(u, True) }),
      [
        decode.at(["file", "url"], decode.string)
        |> decode.map(fn(u) { #(u, False) }),
      ],
    )
  use url_src <- decode.field("image", url_src_decoder)
  use caption <- decode.subfield(
    ["image", "caption"],
    rich_text_markdown_decoder(),
  )
  let #(url, external) = url_src
  decode.success(Image(url, caption, external))
}

fn decode_embed() -> Decoder(Block) {
  use url <- decode.subfield(["embed", "url"], decode.string)
  use caption <- decode.subfield(
    ["embed", "caption"],
    rich_text_markdown_decoder(),
  )
  decode.success(Embed(url, caption))
}

fn decode_bookmark(key: String) -> Decoder(Block) {
  use url <- decode.subfield([key, "url"], decode.string)
  decode.success(Bookmark(url))
}

fn decode_table() -> Decoder(Block) {
  use col <- decode.subfield(
    ["table", "has_column_header"],
    decode.optional(decode.bool),
  )
  use row <- decode.subfield(
    ["table", "has_row_header"],
    decode.optional(decode.bool),
  )
  decode.success(Table([], option.unwrap(col, True), option.unwrap(row, False)))
}

fn decode_table_row() -> Decoder(Block) {
  use cells <- decode.subfield(
    ["table_row", "cells"],
    decode.list(rich_text_markdown_decoder()),
  )
  decode.success(TableRow(cells))
}

fn decode_child_page() -> Decoder(Block) {
  use id <- decode.field("id", decode.optional(decode.string))
  use title <- decode.subfield(
    ["child_page", "title"],
    decode.optional(decode.string),
  )
  decode.success(ChildPage(
    option.unwrap(id, ""),
    option.unwrap(title, ""),
    0,
    [],
    Inlined,
  ))
}

fn decode_child_database() -> Decoder(Block) {
  use id <- decode.field("id", decode.optional(decode.string))
  use title <- decode.subfield(
    ["child_database", "title"],
    decode.optional(decode.string),
  )
  decode.success(ChildDatabase(option.unwrap(id, ""), option.unwrap(title, "")))
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
    Table(_, col, row) -> Table(extract_rows(children), col, row)
    ChildPage(id, title, depth, _, status) ->
      ChildPage(id, title, depth, children, status)
    other -> other
  }
}

fn extract_rows(blocks: List(Block)) -> List(List(String)) {
  case blocks {
    [] -> []
    [TableRow(cells), ..rest] -> [cells, ..extract_rows(rest)]
    [_, ..rest] -> extract_rows(rest)
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
    Image(url, caption, external) -> #(
      pad <> render_image(url, caption, external),
      1,
    )
    Embed(url, caption) -> #(pad <> render_embed(url, caption, pad), 1)
    Bookmark(url) -> #(pad <> "[" <> url <> "](" <> url <> ")", 1)
    Table(rows, _col, row_header) -> #(render_table(rows, row_header, pad), 1)
    TableRow(cells) -> #(pad <> render_row(cells), 1)
    ChildPage(id, title, depth, kids, status) -> #(
      render_child_page(id, title, depth, kids, status, pad, indent),
      1,
    )
    ChildDatabase(id, title) -> #(render_child_database(id, title, pad), 1)
    Unsupported(kind) -> #(pad <> "<!-- unsupported: " <> kind <> " -->", 1)
  }
}

fn render_image(url: String, caption: String, external: Bool) -> String {
  case external {
    True -> Nil
    False ->
      io.println_error(
        "[warn] notion_client/markdown: file-hosted image URL is signed"
        <> " and expires (~1h). URL: "
        <> url,
      )
  }
  "![" <> caption <> "](" <> url <> ")"
}

fn render_embed(url: String, caption: String, pad: String) -> String {
  let iframe = "<iframe src=\"" <> url <> "\"></iframe>"
  case caption {
    "" -> iframe
    _ -> iframe <> "\n" <> pad <> "*" <> caption <> "*"
  }
}

fn render_table(
  rows: List(List(String)),
  row_header: Bool,
  pad: String,
) -> String {
  case rows {
    [] -> pad <> "<!-- empty table -->"
    [header, ..body] -> {
      let width = list.length(header)
      let header_line = pad <> render_row(header)
      let sep_line = pad <> render_separator(width, row_header)
      let body_lines =
        list.map(body, fn(r) { pad <> render_row(pad_row(r, width)) })
      string.join([header_line, sep_line, ..body_lines], "\n")
    }
  }
}

fn render_row(cells: List(String)) -> String {
  "| " <> string.join(list.map(cells, escape_cell), " | ") <> " |"
}

fn escape_cell(text: String) -> String {
  string.replace(text, "|", "\\|")
}

fn render_separator(width: Int, row_header: Bool) -> String {
  case width <= 0 {
    True -> "|---|"
    False -> {
      let cols = separator_cols(width, row_header, 1, [])
      "| " <> string.join(cols, " | ") <> " |"
    }
  }
}

fn separator_cols(
  width: Int,
  row_header: Bool,
  i: Int,
  acc: List(String),
) -> List(String) {
  case i > width {
    True -> list.reverse(acc)
    False -> {
      let col = case row_header, i {
        True, 1 -> ":---"
        _, _ -> "---"
      }
      separator_cols(width, row_header, i + 1, [col, ..acc])
    }
  }
}

fn pad_row(row: List(String), width: Int) -> List(String) {
  let missing = width - list.length(row)
  case missing > 0 {
    True -> list.append(row, list.repeat("", missing))
    False -> row
  }
}

fn render_child_page(
  id: String,
  title: String,
  depth: Int,
  kids: List(Block),
  status: ChildPageStatus,
  pad: String,
  indent: Int,
) -> String {
  case status {
    DepthLimitReached -> pad <> "<!-- child_page:" <> id <> " (depth limit) -->"
    CycleDetected -> pad <> "<!-- child_page:" <> id <> " (cycle) -->"
    Inlined -> {
      let open =
        pad
        <> "<!-- child_page:"
        <> id
        <> " depth="
        <> int.to_string(depth)
        <> " -->"
      let heading = pad <> "## " <> title
      let body = case kids {
        [] -> ""
        _ -> "\n\n" <> render_blocks(kids, indent, 1)
      }
      let close = pad <> "<!-- /child_page:" <> id <> " -->"
      open <> "\n" <> heading <> body <> "\n" <> close
    }
  }
}

fn render_child_database(id: String, title: String, pad: String) -> String {
  pad <> "<!-- child_database:" <> id <> " title=\"" <> title <> "\" -->"
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
    _ ->
      case maybe_table(lines) {
        Some(#(table_json, tail)) -> walk_lines(tail, [table_json, ..acc])
        None ->
          case lines {
            [line, ..rest] ->
              case classify_line(line) {
                ClSkip -> walk_lines(rest, acc)
                ClListItem(_, _, _) -> {
                  let #(items, tail) = consume_list(lines, 0)
                  walk_lines(tail, list.append(list.reverse(items), acc))
                }
                ClNonList(_, j) -> walk_lines(rest, [j, ..acc])
              }
            [] -> list.reverse(acc)
          }
      }
  }
}

fn maybe_table(lines: List(String)) -> Option(#(Json, List(String))) {
  case lines {
    [h, sep, r1, ..rest] ->
      case is_table_line(h), parse_sep_line(sep), is_table_line(r1) {
        True, Some(row_header), True -> {
          let header = split_row(h)
          let width = list.length(header)
          let #(body_rows, tail) = collect_body_rows([r1, ..rest], [])
          let all_rows = [header, ..list.map(body_rows, pad_to(_, width))]
          Some(#(table_json(all_rows, row_header), tail))
        }
        _, _, _ -> None
      }
    _ -> None
  }
}

fn is_table_line(line: String) -> Bool {
  let t = string.trim(line)
  string.contains(t, "|") && !string.starts_with(t, "```")
}

fn parse_sep_line(line: String) -> Option(Bool) {
  let t = string.trim(line)
  case string.contains(t, "|") && string.contains(t, "-") && sep_chars_only(t) {
    False -> None
    True -> {
      // Split and check if first non-empty segment starts with ':'.
      let segs = split_row(t)
      case segs {
        [first, ..] -> Some(string.starts_with(string.trim(first), ":"))
        [] -> Some(False)
      }
    }
  }
}

fn sep_chars_only(s: String) -> Bool {
  case string.pop_grapheme(s) {
    Error(_) -> True
    Ok(#(ch, rest)) ->
      case ch {
        "|" | "-" | ":" | " " | "\t" -> sep_chars_only(rest)
        _ -> False
      }
  }
}

fn collect_body_rows(
  lines: List(String),
  acc: List(List(String)),
) -> #(List(List(String)), List(String)) {
  case lines {
    [] -> #(list.reverse(acc), [])
    [l, ..rest] ->
      case is_table_line(l) {
        True -> collect_body_rows(rest, [split_row(l), ..acc])
        False -> #(list.reverse(acc), lines)
      }
  }
}

fn split_row(line: String) -> List(String) {
  let t = string.trim(line)
  let inner = case string.starts_with(t, "|") {
    True -> string.drop_start(t, 1)
    False -> t
  }
  let inner2 = case string.ends_with(inner, "|") {
    True -> string.drop_end(inner, 1)
    False -> inner
  }
  split_cells(inner2, "", [])
  |> list.map(fn(c) { string.trim(unescape_pipe(c)) })
}

fn split_cells(src: String, current: String, acc: List(String)) -> List(String) {
  case string.pop_grapheme(src) {
    Error(_) -> list.reverse([current, ..acc])
    Ok(#("\\", rest)) ->
      case string.pop_grapheme(rest) {
        Ok(#("|", rest2)) -> split_cells(rest2, current <> "\\|", acc)
        Ok(#(c, rest2)) -> split_cells(rest2, current <> "\\" <> c, acc)
        Error(_) -> list.reverse([current <> "\\", ..acc])
      }
    Ok(#("|", rest)) -> split_cells(rest, "", [current, ..acc])
    Ok(#(c, rest)) -> split_cells(rest, current <> c, acc)
  }
}

fn unescape_pipe(s: String) -> String {
  string.replace(s, "\\|", "|")
}

fn pad_to(row: List(String), width: Int) -> List(String) {
  let missing = width - list.length(row)
  case missing > 0 {
    True -> list.append(row, list.repeat("", missing))
    False ->
      case missing < 0 {
        True -> list.take(row, width)
        False -> row
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
    "![" <> _ ->
      case parse_image_line(content) {
        Ok(#(caption, url)) -> image_json(url, caption)
        Error(_) -> paragraph_json(content)
      }
    "<iframe" <> _ ->
      case parse_iframe_line(content) {
        Ok(url) -> embed_json(url)
        Error(_) -> paragraph_json(content)
      }
    _ -> paragraph_json(content)
  }
}

fn parse_image_line(content: String) -> Result(#(String, String), Nil) {
  case content {
    "![" <> rest ->
      case split_caption_url(rest, "") {
        Ok(#(caption, url)) -> Ok(#(caption, url))
        Error(_) -> Error(Nil)
      }
    _ -> Error(Nil)
  }
}

fn parse_iframe_line(content: String) -> Result(String, Nil) {
  let trimmed = string.trim(content)
  let closed =
    string.ends_with(trimmed, "</iframe>") || string.ends_with(trimmed, "/>")
  case closed {
    False -> Error(Nil)
    True -> extract_src(trimmed)
  }
}

fn extract_src(line: String) -> Result(String, Nil) {
  case string.split_once(line, "src=\"") {
    Ok(#(_, after)) ->
      case string.split_once(after, "\"") {
        Ok(#(url, _)) ->
          case url {
            "" -> Error(Nil)
            _ -> Ok(url)
          }
        Error(_) -> Error(Nil)
      }
    Error(_) -> Error(Nil)
  }
}

fn split_caption_url(
  src: String,
  caption_acc: String,
) -> Result(#(String, String), Nil) {
  case src {
    "](" <> after -> {
      case string.ends_with(after, ")") {
        True -> {
          let url = string.drop_end(after, 1)
          case url {
            "" -> Error(Nil)
            _ -> Ok(#(caption_acc, url))
          }
        }
        False -> Error(Nil)
      }
    }
    "" -> Error(Nil)
    _ ->
      case string.pop_grapheme(src) {
        Ok(#(ch, rest)) -> split_caption_url(rest, caption_acc <> ch)
        Error(_) -> Error(Nil)
      }
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

fn image_json(url: String, caption: String) -> Json {
  block_json(
    "image",
    json.object([
      #("type", json.string("external")),
      #("external", json.object([#("url", json.string(url))])),
      #("caption", rich_text_json(caption)),
    ]),
  )
}

fn table_json(rows: List(List(String)), has_row_header: Bool) -> Json {
  let width = case rows {
    [first, ..] -> list.length(first)
    [] -> 0
  }
  let row_blocks =
    list.map(rows, fn(cells) {
      block_json(
        "table_row",
        json.object([
          #("cells", json.array(cells, fn(c) { rich_text_json(c) })),
        ]),
      )
    })
  block_json(
    "table",
    json.object([
      #("table_width", json.int(width)),
      #("has_column_header", json.bool(True)),
      #("has_row_header", json.bool(has_row_header)),
      #("children", json.array(row_blocks, fn(j) { j })),
    ]),
  )
}

fn embed_json(url: String) -> Json {
  block_json(
    "embed",
    json.object([
      #("url", json.string(url)),
      #("caption", json.array([], fn(x) { x })),
    ]),
  )
}

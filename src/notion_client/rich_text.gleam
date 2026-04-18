//// Rich text: Notion rich_text ↔ markdown runs.
////
//// A `Run` is a single span of text with a flat set of annotations.
//// `runs_to_markdown` / `markdown_to_runs` convert between Run lists and
//// markdown strings; `runs_to_json` / `run_list_decoder` convert between
//// Run lists and Notion rich_text arrays.
////
//// Scope (v2, phase 16): bold, italic, strikethrough, code, underline,
//// span-colour, and links. Mentions and equations are not produced on
//// write; on read they degrade to plain text / passthrough href.

import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

pub type Run {
  Run(
    text: String,
    bold: Bool,
    italic: Bool,
    strikethrough: Bool,
    code: Bool,
    underline: Bool,
    color: String,
    href: Option(String),
  )
}

pub fn plain(text: String) -> Run {
  Run(
    text: text,
    bold: False,
    italic: False,
    strikethrough: False,
    code: False,
    underline: False,
    color: "default",
    href: None,
  )
}

// ─── runs → markdown ────────────────────────────────────────────────────

pub fn runs_to_markdown(runs: List(Run)) -> String {
  runs
  |> collapse
  |> list.map(render_run)
  |> string.join("")
}

fn render_run(run: Run) -> String {
  let t = escape(run.text)
  let t = case run.code {
    True -> "`" <> t <> "`"
    False -> t
  }
  let t = case run.strikethrough {
    True -> "~~" <> t <> "~~"
    False -> t
  }
  let t = case run.bold {
    True -> "**" <> t <> "**"
    False -> t
  }
  let t = case run.italic {
    True -> "*" <> t <> "*"
    False -> t
  }
  let t = case run.underline {
    True -> "<u>" <> t <> "</u>"
    False -> t
  }
  let t = case run.color {
    "default" -> t
    c -> "<span style=\"color:" <> c <> "\">" <> t <> "</span>"
  }
  case run.href {
    Some(url) -> "[" <> t <> "](" <> url <> ")"
    None -> t
  }
}

fn escape(text: String) -> String {
  text
  |> string.replace("\\", "\\\\")
  |> string.replace("*", "\\*")
  |> string.replace("_", "\\_")
  |> string.replace("`", "\\`")
  |> string.replace("[", "\\[")
  |> string.replace("]", "\\]")
}

fn collapse(runs: List(Run)) -> List(Run) {
  case runs {
    [] -> []
    [first, ..rest] -> collapse_loop(rest, first, [])
  }
}

fn collapse_loop(
  remaining: List(Run),
  current: Run,
  acc: List(Run),
) -> List(Run) {
  case remaining {
    [] -> list.reverse([current, ..acc])
    [next, ..rest] ->
      case same_annotations(current, next) {
        True ->
          collapse_loop(
            rest,
            Run(..current, text: current.text <> next.text),
            acc,
          )
        False -> collapse_loop(rest, next, [current, ..acc])
      }
  }
}

fn same_annotations(a: Run, b: Run) -> Bool {
  a.bold == b.bold
  && a.italic == b.italic
  && a.strikethrough == b.strikethrough
  && a.code == b.code
  && a.underline == b.underline
  && a.color == b.color
  && a.href == b.href
}

// ─── markdown → runs ────────────────────────────────────────────────────

pub fn markdown_to_runs(source: String) -> List(Run) {
  let #(runs, _rest, _closed) = do_parse(source, plain(""), None, "", [])
  collapse(runs)
}

type ParseResult =
  #(List(Run), String, Bool)

fn do_parse(
  src: String,
  annot: Run,
  stop: Option(String),
  buf: String,
  acc: List(Run),
) -> ParseResult {
  case stop {
    Some(s) ->
      case string.starts_with(src, s) {
        True -> #(
          flush(buf, annot, acc),
          string.drop_start(src, string.length(s)),
          True,
        )
        False -> step(src, annot, stop, buf, acc)
      }
    None -> step(src, annot, stop, buf, acc)
  }
}

fn step(
  src: String,
  annot: Run,
  stop: Option(String),
  buf: String,
  acc: List(Run),
) -> ParseResult {
  case src {
    "" -> #(flush(buf, annot, acc), "", option.is_none(stop))
    "\\" <> rest ->
      case string.pop_grapheme(rest) {
        Ok(#(c, r)) -> do_parse(r, annot, stop, buf <> c, acc)
        Error(_) -> do_parse("", annot, stop, buf <> "\\", acc)
      }
    "**" <> rest ->
      emph(rest, "**", "**", annot, stop, buf, acc, Run(..annot, bold: True))
    "~~" <> rest ->
      emph(
        rest,
        "~~",
        "~~",
        annot,
        stop,
        buf,
        acc,
        Run(..annot, strikethrough: True),
      )
    "*" <> rest ->
      emph(rest, "*", "*", annot, stop, buf, acc, Run(..annot, italic: True))
    "`" <> rest -> code_span(rest, annot, stop, buf, acc)
    "[" <> rest -> link(rest, annot, stop, buf, acc)
    "<u>" <> rest ->
      emph(
        rest,
        "<u>",
        "</u>",
        annot,
        stop,
        buf,
        acc,
        Run(..annot, underline: True),
      )
    "<span style=\"color:" <> rest -> color_span(rest, annot, stop, buf, acc)
    _ ->
      case string.pop_grapheme(src) {
        Ok(#(c, r)) -> do_parse(r, annot, stop, buf <> c, acc)
        Error(_) -> #(flush(buf, annot, acc), "", option.is_none(stop))
      }
  }
}

fn emph(
  after_open: String,
  opener: String,
  close: String,
  annot: Run,
  stop: Option(String),
  buf: String,
  acc: List(Run),
  new_annot: Run,
) -> ParseResult {
  let #(inner, rest, closed) =
    do_parse(after_open, new_annot, Some(close), "", [])
  case closed {
    True -> {
      let acc1 = flush(buf, annot, acc)
      do_parse(rest, annot, stop, "", list.append(acc1, inner))
    }
    False -> push_literal(opener, after_open, annot, stop, buf, acc)
  }
}

fn code_span(
  src: String,
  annot: Run,
  stop: Option(String),
  buf: String,
  acc: List(Run),
) -> ParseResult {
  case string.split_once(src, "`") {
    Ok(#(content, rest)) -> {
      let acc1 = flush(buf, annot, acc)
      let code_run = Run(..annot, text: content, code: True)
      do_parse(rest, annot, stop, "", list.append(acc1, [code_run]))
    }
    Error(_) -> push_literal("`", src, annot, stop, buf, acc)
  }
}

fn link(
  src: String,
  annot: Run,
  stop: Option(String),
  buf: String,
  acc: List(Run),
) -> ParseResult {
  let #(inner, rest, closed) = do_parse(src, annot, Some("]"), "", [])
  case closed, rest {
    True, "(" <> after_paren ->
      case string.split_once(after_paren, ")") {
        Ok(#(url, tail)) -> {
          let acc1 = flush(buf, annot, acc)
          let linked = list.map(inner, fn(r) { Run(..r, href: Some(url)) })
          do_parse(tail, annot, stop, "", list.append(acc1, linked))
        }
        Error(_) -> push_literal("[", src, annot, stop, buf, acc)
      }
    _, _ -> push_literal("[", src, annot, stop, buf, acc)
  }
}

fn color_span(
  src: String,
  annot: Run,
  stop: Option(String),
  buf: String,
  acc: List(Run),
) -> ParseResult {
  case string.split_once(src, "\">") {
    Ok(#(color, after_close_tag)) -> {
      let new_annot = Run(..annot, color: color)
      let #(inner, rest, closed) =
        do_parse(after_close_tag, new_annot, Some("</span>"), "", [])
      case closed {
        True -> {
          let acc1 = flush(buf, annot, acc)
          do_parse(rest, annot, stop, "", list.append(acc1, inner))
        }
        False ->
          push_literal("<span style=\"color:", src, annot, stop, buf, acc)
      }
    }
    Error(_) -> push_literal("<span style=\"color:", src, annot, stop, buf, acc)
  }
}

fn push_literal(
  opener: String,
  rest_after: String,
  annot: Run,
  stop: Option(String),
  buf: String,
  acc: List(Run),
) -> ParseResult {
  case string.pop_grapheme(opener) {
    Ok(#(c, rest_op)) ->
      do_parse(rest_op <> rest_after, annot, stop, buf <> c, acc)
    Error(_) -> do_parse(rest_after, annot, stop, buf, acc)
  }
}

fn flush(buf: String, annot: Run, acc: List(Run)) -> List(Run) {
  case buf {
    "" -> acc
    _ -> list.append(acc, [Run(..annot, text: buf)])
  }
}

// ─── runs ↔ JSON ────────────────────────────────────────────────────────

pub fn runs_to_json(runs: List(Run)) -> Json {
  json.array(collapse(runs), run_to_json_item)
}

fn run_to_json_item(run: Run) -> Json {
  let link = case run.href {
    Some(url) -> json.object([#("url", json.string(url))])
    None -> json.null()
  }
  json.object([
    #("type", json.string("text")),
    #(
      "text",
      json.object([#("content", json.string(run.text)), #("link", link)]),
    ),
    #(
      "annotations",
      json.object([
        #("bold", json.bool(run.bold)),
        #("italic", json.bool(run.italic)),
        #("strikethrough", json.bool(run.strikethrough)),
        #("underline", json.bool(run.underline)),
        #("code", json.bool(run.code)),
        #("color", json.string(run.color)),
      ]),
    ),
  ])
}

pub fn run_list_decoder() -> Decoder(List(Run)) {
  decode.list(run_decoder())
}

fn run_decoder() -> Decoder(Run) {
  use plain_text <- decode.field("plain_text", decode.optional(decode.string))
  use bold <- decode.optional_field(
    "annotations",
    False,
    annot_bool_decoder("bold"),
  )
  use italic <- decode.optional_field(
    "annotations",
    False,
    annot_bool_decoder("italic"),
  )
  use strike <- decode.optional_field(
    "annotations",
    False,
    annot_bool_decoder("strikethrough"),
  )
  use underline <- decode.optional_field(
    "annotations",
    False,
    annot_bool_decoder("underline"),
  )
  use code <- decode.optional_field(
    "annotations",
    False,
    annot_bool_decoder("code"),
  )
  use color <- decode.optional_field(
    "annotations",
    "default",
    annot_string_decoder("color", "default"),
  )
  use href <- decode.optional_field(
    "href",
    None,
    decode.optional(decode.string),
  )
  decode.success(Run(
    text: option.unwrap(plain_text, ""),
    bold: bold,
    italic: italic,
    strikethrough: strike,
    underline: underline,
    code: code,
    color: color,
    href: href,
  ))
}

fn annot_bool_decoder(key: String) -> Decoder(Bool) {
  {
    use v <- decode.field(key, decode.optional(decode.bool))
    decode.success(option.unwrap(v, False))
  }
}

fn annot_string_decoder(key: String, default: String) -> Decoder(String) {
  {
    use v <- decode.field(key, decode.optional(decode.string))
    decode.success(option.unwrap(v, default))
  }
}

//// Unit tests for `markdown.to_markdown_annotated`: every block
//// (including nested) is preceded by a `[//]: # (notion_block_id: …)`
//// comment line at matching indent.

import gleam/string
import gleeunit/should
import notion_client/markdown

pub fn main() {
  Nil
}

fn ab(id: String, b: markdown.Block) -> markdown.AnnotatedBlock {
  markdown.AnnotatedBlock(id, b, [])
}

fn ab_kids(
  id: String,
  b: markdown.Block,
  kids: List(markdown.AnnotatedBlock),
) -> markdown.AnnotatedBlock {
  markdown.AnnotatedBlock(id, b, kids)
}

pub fn prefixes_every_top_level_block_test() {
  let blocks = [
    ab("id-1", markdown.Paragraph("hello", [])),
    ab("id-2", markdown.ToDo("buy milk", False)),
  ]
  let out = markdown.to_markdown_annotated(blocks)
  should.equal(string.contains(out, "[//]: # (notion_block_id: id-1)"), True)
  should.equal(string.contains(out, "[//]: # (notion_block_id: id-2)"), True)
  // Order: annotation for id-1 precedes its body, then id-2.
  let i1 = unwrap_index(string.split_once(out, "[//]: # (notion_block_id: id-1)"))
  let i2 = unwrap_index(string.split_once(out, "[//]: # (notion_block_id: id-2)"))
  should.equal(i1 < i2, True)
  should.equal(string.contains(out, "- [ ] buy milk"), True)
}

pub fn nested_children_are_annotated_and_indented_test() {
  let inner =
    ab("inner", markdown.BulletedListItem("child", []))
  let outer =
    ab_kids(
      "outer",
      markdown.BulletedListItem("parent", []),
      [inner],
    )
  let out = markdown.to_markdown_annotated([outer])
  should.equal(string.contains(out, "[//]: # (notion_block_id: outer)"), True)
  // Inner annotation indented by two spaces.
  should.equal(
    string.contains(out, "  [//]: # (notion_block_id: inner)"),
    True,
  )
  should.equal(string.contains(out, "  - child"), True)
}

pub fn todo_checked_renders_with_annotation_test() {
  let out =
    markdown.to_markdown_annotated([
      ab("abc", markdown.ToDo("done", True)),
    ])
  should.equal(string.contains(out, "[//]: # (notion_block_id: abc)"), True)
  should.equal(string.contains(out, "- [x] done"), True)
}

fn unwrap_index(r: Result(#(String, String), Nil)) -> Int {
  case r {
    Ok(#(before, _)) -> string.length(before)
    Error(_) -> -1
  }
}

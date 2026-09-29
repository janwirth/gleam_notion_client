//// Smoke test: annotated renderer emits the link-label comment used by
//// agents to address blocks. The wire behaviour (fetch/check) is
//// covered by the notion_client test suite and live tests.

import gleam/string
import gleeunit
import gleeunit/should
import notion_client/markdown

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn annotated_renderer_emits_block_id_comment_test() {
  let blocks = [
    markdown.AnnotatedBlock("abc-123", markdown.ToDo("task", False), []),
  ]
  let out = markdown.to_markdown_annotated(blocks)
  should.equal(
    string.contains(out, "[//]: # (notion_block_id: abc-123)"),
    True,
  )
  should.equal(string.contains(out, "- [ ] task"), True)
}

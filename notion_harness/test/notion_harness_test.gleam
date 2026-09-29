import gleeunit
import notion_harness.{Found, LookupError, Missing, PrincessTodo}

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn usage_not_empty_test() {
  let u = notion_harness.usage()
  assert u != ""
  Nil
}

pub fn parse_missing_test() {
  let raw = "{\"status\":\"missing\"}"
  assert notion_harness.parse_princess_json(raw) == Missing
  Nil
}

pub fn parse_found_test() {
  let raw =
    "{\"status\":\"found\",\"callout_block_id\":\"c-1\","
    <> "\"todos\":[{\"id\":\"t-1\",\"text\":\"first\",\"checked\":false}],"
    <> "\"content_markdown\":\"extra notes\"}"
  assert notion_harness.parse_princess_json(raw)
    == Found(
      "c-1",
      [PrincessTodo(id: "t-1", text: "first", checked: False, depth: 0)],
      "extra notes",
    )
  Nil
}

// Older notion_cli builds didn't emit content_markdown. Ensure the
// decoder still accepts those payloads for graceful rollout.
pub fn parse_found_without_content_markdown_test() {
  let raw =
    "{\"status\":\"found\",\"callout_block_id\":\"c-1\","
    <> "\"todos\":[{\"id\":\"t-1\",\"text\":\"first\",\"checked\":false}]}"
  assert notion_harness.parse_princess_json(raw)
    == Found(
      "c-1",
      [PrincessTodo(id: "t-1", text: "first", checked: False, depth: 0)],
      "",
    )
  Nil
}

pub fn parse_found_with_depth_test() {
  let raw =
    "{\"status\":\"found\",\"callout_block_id\":\"c-1\","
    <> "\"todos\":[{\"id\":\"t-1\",\"text\":\"top\",\"checked\":false,\"depth\":0},"
    <> "{\"id\":\"t-2\",\"text\":\"sub\",\"checked\":false,\"depth\":2}],"
    <> "\"content_markdown\":\"\"}"
  assert notion_harness.parse_princess_json(raw)
    == Found(
      "c-1",
      [
        PrincessTodo(id: "t-1", text: "top", checked: False, depth: 0),
        PrincessTodo(id: "t-2", text: "sub", checked: False, depth: 2),
      ],
      "",
    )
  Nil
}

pub fn parse_garbage_test() {
  case notion_harness.parse_princess_json("not json") {
    LookupError(_) -> Nil
    _ -> panic as "expected LookupError for garbage input"
  }
}

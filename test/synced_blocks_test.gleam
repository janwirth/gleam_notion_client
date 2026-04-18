//// Unit tests for phase-23 synced_block rendering + decoding.
//// Covers original vs reference decoder shape, four render states
//// (original, reference stub, inlined expansion, cycle), and
//// with_children merging for the original form.

import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import notion_client/markdown

pub fn main() {
  Nil
}

fn parse_block(j: String) -> markdown.Block {
  let assert Ok(b) = json.parse(j, markdown.block_decoder())
  b
}

// ─── decoder ───────────────────────────────────────────────────────────

pub fn read_synced_original_test() {
  let b =
    parse_block(
      "{\"type\":\"synced_block\",\"id\":\"orig1\","
      <> "\"synced_block\":{\"synced_from\":null}}",
    )
  should.equal(
    b,
    markdown.SyncedBlock("orig1", None, [], markdown.SyncedOriginal),
  )
}

pub fn read_synced_reference_test() {
  let b =
    parse_block(
      "{\"type\":\"synced_block\",\"id\":\"ref1\","
      <> "\"synced_block\":{\"synced_from\":{\"block_id\":\"orig1\"}}}",
    )
  should.equal(
    b,
    markdown.SyncedBlock("ref1", Some("orig1"), [], markdown.SyncedReference),
  )
}

// ─── render ────────────────────────────────────────────────────────────

pub fn render_synced_original_empty_test() {
  let sb = markdown.SyncedBlock("orig1", None, [], markdown.SyncedOriginal)
  let out = markdown.to_markdown([sb])
  should.equal(out, "<!-- synced_block:orig1 -->\n<!-- /synced_block:orig1 -->")
}

pub fn render_synced_original_with_body_test() {
  let kids = [markdown.Paragraph("hello", [])]
  let sb = markdown.SyncedBlock("orig1", None, kids, markdown.SyncedOriginal)
  let out = markdown.to_markdown([sb])
  should.equal(
    out,
    "<!-- synced_block:orig1 -->\nhello\n<!-- /synced_block:orig1 -->",
  )
}

pub fn render_synced_reference_test() {
  let sb =
    markdown.SyncedBlock("ref1", Some("orig1"), [], markdown.SyncedReference)
  let out = markdown.to_markdown([sb])
  should.equal(out, "<!-- synced_from:orig1 -->")
}

pub fn render_synced_inlined_test() {
  let kids = [markdown.Paragraph("body", [])]
  let sb =
    markdown.SyncedBlock("ref1", Some("orig1"), kids, markdown.SyncedInlined)
  let out = markdown.to_markdown([sb])
  should.equal(
    out,
    "<!-- synced_from:orig1 -->\nbody\n<!-- /synced_from:orig1 -->",
  )
}

pub fn render_synced_cycle_test() {
  let sb = markdown.SyncedBlock("ref1", Some("orig1"), [], markdown.SyncedCycle)
  let out = markdown.to_markdown([sb])
  should.equal(out, "<!-- synced_from:orig1 (cycle) -->")
}

// ─── with_children ─────────────────────────────────────────────────────

pub fn with_children_synced_original_test() {
  let parent = markdown.SyncedBlock("orig1", None, [], markdown.SyncedOriginal)
  let kids = [markdown.Paragraph("hi", [])]
  let merged = markdown.with_children(parent, kids)
  should.equal(
    merged,
    markdown.SyncedBlock("orig1", None, kids, markdown.SyncedOriginal),
  )
}

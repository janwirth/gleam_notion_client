//// Shared helpers for `*_live_test.gleam` modules. Every live test
//// creates a row in the reference database, exercises a feature, then
//// the next run (in record/refresh mode) needs to archive the previous
//// row so the DB does not accumulate duplicates.
////
//// Callers are already gated on `NOTION_TOKEN` +
//// `NOTION_BOOTSTRAP_DATABASE_ID`, so these helpers do no env checks of
//// their own. The companion `ensure_schema` is a stub in task 26 — task
//// 27 fills it in with a PATCH that converges the canonical schema.

import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import notion_client

/// POST /v1/pages with parent = `database_id: db_id`. Title column is
/// `Name` with a single plain-text run; caller supplies any additional
/// property fields via `extra_properties`. Returns the new page id.
pub fn create_row(
  client: notion_client.Client,
  db_id: String,
  title: String,
  extra_properties: List(#(String, json.Json)),
) -> String {
  let name_field = #(
    "Name",
    json.object([
      #(
        "title",
        json.array([title], fn(t) {
          json.object([
            #("type", json.string("text")),
            #("text", json.object([#("content", json.string(t))])),
          ])
        }),
      ),
    ]),
  )
  let body =
    json.object([
      #("parent", json.object([#("database_id", json.string(db_id))])),
      #("properties", json.object([name_field, ..extra_properties])),
    ])
  let req =
    notion_client.base_request(client)
    |> request.set_method(http.Post)
    |> request.set_path("/v1/pages")
    |> request.set_body(<<json.to_string(body):utf8>>)
  let assert Ok(resp) = notion_client.request(client, req)
  assert resp.status == 200
  let id_decoder = {
    use id <- decode.field("id", decode.string)
    decode.success(id)
  }
  let assert Ok(id) = json.parse_bits(resp.body, id_decoder)
  id
}

/// Archive every page in `db_id` whose `Name` title equals `title`.
/// Pagination-safe; walks `next_cursor` until the server reports
/// `has_more: false`. No-op when nothing matches.
pub fn archive_by_title(
  client: notion_client.Client,
  db_id: String,
  title: String,
) -> Nil {
  let filter =
    json.object([
      #("property", json.string("Name")),
      #("title", json.object([#("equals", json.string(title))])),
    ])
  archive_loop(client, db_id, Some(filter), None)
}

/// Archive every non-archived page in `db_id`. Intended for the
/// one-shot `cleanup_live_test` (task 30), not per-test cleanup.
pub fn archive_all_rows(client: notion_client.Client, db_id: String) -> Nil {
  archive_loop(client, db_id, None, None)
}

/// Stub — task 27 replaces this body with a PATCH that converges the
/// canonical v3 schema. Keeping the signature stable now so dependent
/// tasks can wire the call site.
pub fn ensure_schema(_client: notion_client.Client, _db_id: String) -> Nil {
  Nil
}

fn archive_loop(
  client: notion_client.Client,
  db_id: String,
  filter: Option(json.Json),
  cursor: Option(String),
) -> Nil {
  let fields = [
    #("page_size", json.int(100)),
    ..case cursor {
      Some(c) -> [#("start_cursor", json.string(c))]
      None -> []
    }
  ]
  let base_fields = case filter {
    Some(f) -> [#("filter", f), ..fields]
    None -> fields
  }
  let body = json.object(base_fields)
  let req =
    notion_client.base_request(client)
    |> request.set_method(http.Post)
    |> request.set_path("/v1/databases/" <> db_id <> "/query")
    |> request.set_body(<<json.to_string(body):utf8>>)
  let assert Ok(resp) = notion_client.request(client, req)
  assert resp.status == 200
  let decoder = {
    use ids <- decode.field(
      "results",
      decode.list({
        use id <- decode.field("id", decode.string)
        decode.success(id)
      }),
    )
    use has_more <- decode.field("has_more", decode.bool)
    use next <- decode.field("next_cursor", decode.optional(decode.string))
    decode.success(#(ids, has_more, next))
  }
  let assert Ok(#(ids, has_more, next)) = json.parse_bits(resp.body, decoder)
  list.each(ids, fn(id) { archive_page(client, id) })
  case has_more, next {
    True, Some(c) -> archive_loop(client, db_id, filter, Some(c))
    _, _ -> Nil
  }
}

fn archive_page(client: notion_client.Client, page_id: String) -> Nil {
  let body = json.object([#("archived", json.bool(True))])
  let req =
    notion_client.base_request(client)
    |> request.set_method(http.Patch)
    |> request.set_path("/v1/pages/" <> page_id)
    |> request.set_body(<<json.to_string(body):utf8>>)
  let assert Ok(resp) = notion_client.request(client, req)
  assert resp.status == 200
  Nil
}

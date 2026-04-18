//// Code-generation entrypoint. Not shipped — lives in test/ so it stays out
//// of the published library (per oas_generator README).
////
//// Run with: `gleam run -m notion_client/dev`

import gleam/io
import oas/generator
import snag

pub fn main() -> Nil {
  case generator.build("./openapi.json", ".", "notion_client", []) {
    Ok(_) ->
      io.println(
        "oas_generator: wrote src/notion_client/{operations,schema}.gleam",
      )
    Error(reason) -> io.print(snag.pretty_print(reason))
  }
}

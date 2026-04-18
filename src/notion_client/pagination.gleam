//// Cursor pagination helpers for Notion list endpoints.
////
//// Notion list responses share the shape `{ results, has_more,
//// next_cursor }`. Each generated `*_response` decoder produces a
//// distinct typed record, so this module is generic over the item
//// type via a [`ListFn`](#ListFn) callback that the caller writes
//// once per endpoint to bridge "ask for cursor X" → `Page(item)`.
////
//// Two helpers are provided:
////   * [`collect`](#collect) — eager: walks every page, returns
////     `Result(List(item), error)`.
////   * [`iterate`](#iterate) — lazy: returns a
////     `Yielder(Result(item, error))` that fetches the next page only
////     when the consumer drains the buffered items. A page-fetch error
////     is yielded once and then the yielder halts.

import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/yielder.{type Yielder, Done, Next}

/// One page of a paginated response, normalised. `next_cursor` being
/// `Some(_)` means more pages exist; `None` means this is the last
/// page (regardless of whether the API also returned `has_more:
/// false`). Callers must collapse `has_more && Some(cursor)` into
/// `Some(cursor)` and everything else into `None`.
pub type Page(item) {
  Page(items: List(item), next_cursor: Option(String))
}

/// Fetch one page given the cursor for that page (`None` for the
/// first call). Errors are propagated unchanged so the caller can use
/// any error type — `NotionError` in production, anything in tests.
pub type ListFn(item, error) =
  fn(Option(String)) -> Result(Page(item), error)

/// Walk every page eagerly, accumulating items. Stops on the first
/// error and returns it. Memory is O(total items).
pub fn collect(list_fn: ListFn(item, error)) -> Result(List(item), error) {
  case collect_loop(list_fn, None, []) {
    Error(e) -> Error(e)
    Ok(reversed) -> Ok(list.reverse(reversed))
  }
}

fn collect_loop(
  list_fn: ListFn(item, error),
  cursor: Option(String),
  acc: List(item),
) -> Result(List(item), error) {
  case list_fn(cursor) {
    Error(e) -> Error(e)
    Ok(Page(items, next)) -> {
      let acc2 = prepend_all(items, acc)
      case next {
        None -> Ok(acc2)
        Some(_) -> collect_loop(list_fn, next, acc2)
      }
    }
  }
}

fn prepend_all(items: List(a), acc: List(a)) -> List(a) {
  case items {
    [] -> acc
    [x, ..rest] -> prepend_all(rest, [x, ..acc])
  }
}

/// Walk pages lazily. The yielder buffers one page at a time;
/// fetching the next page is deferred until the consumer drains the
/// buffer. Errors are surfaced as `Error(_)` then the yielder halts.
pub fn iterate(list_fn: ListFn(item, error)) -> Yielder(Result(item, error)) {
  yielder.unfold(from: Pull([], Begin), with: fn(state) { step(list_fn, state) })
}

type Cursor {
  Begin
  More(String)
  End
}

type State(item) {
  Pull(buffer: List(item), next: Cursor)
  Halt
}

fn step(
  list_fn: ListFn(item, error),
  state: State(item),
) -> yielder.Step(Result(item, error), State(item)) {
  case state {
    Halt -> Done
    Pull([first, ..rest], next) -> Next(Ok(first), Pull(rest, next))
    Pull([], End) -> Done
    Pull([], cursor) -> {
      let req = case cursor {
        Begin -> None
        More(c) -> Some(c)
        End -> None
      }
      case list_fn(req) {
        Error(e) -> Next(Error(e), Halt)
        Ok(Page(items, next_cursor)) -> {
          let next = case next_cursor {
            Some(c) -> More(c)
            None -> End
          }
          step(list_fn, Pull(items, next))
        }
      }
    }
  }
}

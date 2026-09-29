-module(notion_harness).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/notion_harness.gleam").
-export([parse_princess_json/1, find_princess_callout/1, find_princess_callout_all/1, fetch_page_title/1, create_princess_callout/1, usage/0]).
-export_type([princess_todo/0, princess_lookup/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-type princess_todo() :: {princess_todo,
        binary(),
        binary(),
        boolean(),
        integer()}.

-type princess_lookup() :: {found, binary(), list(princess_todo()), binary()} |
    missing |
    {lookup_error, binary()}.

-file("src/notion_harness.gleam", 176).
-spec princess_todo_decoder() -> gleam@dynamic@decode:decoder(princess_todo()).
princess_todo_decoder() ->
    gleam@dynamic@decode:field(
        <<"id"/utf8>>,
        {decoder, fun gleam@dynamic@decode:decode_string/1},
        fun(Id) ->
            gleam@dynamic@decode:field(
                <<"text"/utf8>>,
                {decoder, fun gleam@dynamic@decode:decode_string/1},
                fun(Text) ->
                    gleam@dynamic@decode:field(
                        <<"checked"/utf8>>,
                        {decoder, fun gleam@dynamic@decode:decode_bool/1},
                        fun(Checked) ->
                            gleam@dynamic@decode:optional_field(
                                <<"depth"/utf8>>,
                                0,
                                {decoder, fun gleam@dynamic@decode:decode_int/1},
                                fun(Depth) ->
                                    gleam@dynamic@decode:success(
                                        {princess_todo,
                                            Id,
                                            Text,
                                            Checked,
                                            Depth}
                                    )
                                end
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/notion_harness.gleam", 156).
-spec princess_decoder() -> gleam@dynamic@decode:decoder(princess_lookup()).
princess_decoder() ->
    gleam@dynamic@decode:field(
        <<"status"/utf8>>,
        {decoder, fun gleam@dynamic@decode:decode_string/1},
        fun(Status) -> case Status of
                <<"missing"/utf8>> ->
                    gleam@dynamic@decode:success(missing);

                <<"found"/utf8>> ->
                    gleam@dynamic@decode:field(
                        <<"callout_block_id"/utf8>>,
                        {decoder, fun gleam@dynamic@decode:decode_string/1},
                        fun(Callout_id) ->
                            gleam@dynamic@decode:field(
                                <<"todos"/utf8>>,
                                gleam@dynamic@decode:list(
                                    princess_todo_decoder()
                                ),
                                fun(Todos) ->
                                    gleam@dynamic@decode:optional_field(
                                        <<"content_markdown"/utf8>>,
                                        <<""/utf8>>,
                                        {decoder,
                                            fun gleam@dynamic@decode:decode_string/1},
                                        fun(Content_markdown) ->
                                            gleam@dynamic@decode:success(
                                                {found,
                                                    Callout_id,
                                                    Todos,
                                                    Content_markdown}
                                            )
                                        end
                                    )
                                end
                            )
                        end
                    );

                Other ->
                    gleam@dynamic@decode:success(
                        {lookup_error,
                            <<"unknown status: "/utf8, Other/binary>>}
                    )
            end end
    ).

-file("src/notion_harness.gleam", 149).
?DOC(
    " Parse the JSON emitted by `notion_cli princess --json`. Exposed for\n"
    " tests + callers that already have the raw output (e.g. piped from\n"
    " a shell script).\n"
).
-spec parse_princess_json(binary()) -> princess_lookup().
parse_princess_json(Raw) ->
    case gleam@json:parse(Raw, princess_decoder()) of
        {ok, V} ->
            V;

        {error, _} ->
            {lookup_error,
                <<"could not parse notion_cli JSON: "/utf8, Raw/binary>>}
    end.

-file("src/notion_harness.gleam", 191).
-spec is_uuid_like(binary()) -> boolean().
is_uuid_like(S) ->
    Hex_chars = [<<"0"/utf8>>,
        <<"1"/utf8>>,
        <<"2"/utf8>>,
        <<"3"/utf8>>,
        <<"4"/utf8>>,
        <<"5"/utf8>>,
        <<"6"/utf8>>,
        <<"7"/utf8>>,
        <<"8"/utf8>>,
        <<"9"/utf8>>,
        <<"a"/utf8>>,
        <<"b"/utf8>>,
        <<"c"/utf8>>,
        <<"d"/utf8>>,
        <<"e"/utf8>>,
        <<"f"/utf8>>,
        <<"A"/utf8>>,
        <<"B"/utf8>>,
        <<"C"/utf8>>,
        <<"D"/utf8>>,
        <<"E"/utf8>>,
        <<"F"/utf8>>,
        <<"-"/utf8>>],
    N = string:length(S),
    ((N =:= 32) orelse (N =:= 36)) andalso gleam@list:all(
        gleam@string:to_graphemes(S),
        fun(G) -> gleam@list:contains(Hex_chars, G) end
    ).

-file("src/notion_harness.gleam", 203).
-spec shell_quote(binary()) -> binary().
shell_quote(S) ->
    <<<<"'"/utf8,
            (gleam@string:replace(S, <<"'"/utf8>>, <<"'\\''"/utf8>>))/binary>>/binary,
        "'"/utf8>>.

-file("src/notion_harness.gleam", 79).
?DOC(
    " Shell out to `notion_cli princess <page_id> --json` and parse the\n"
    " structured output into a [`PrincessLookup`](#PrincessLookup).\n"
    "\n"
    " Inherits the notion_cli environment (NOTION_TOKEN, NOTION_API_VERSION)\n"
    " from the current process; assumes `notion_cli` is on $PATH. Use this\n"
    " from an empress server so you can render the open-todo list BEFORE\n"
    " handing anything to Claude.\n"
).
-spec find_princess_callout(binary()) -> princess_lookup().
find_princess_callout(Page_id) ->
    Cmd = <<<<"notion_cli princess "/utf8, (shell_quote(Page_id))/binary>>/binary,
        " --json 2>/dev/null"/utf8>>,
    Raw = gleam@string:trim(notion_harness_ffi:os_cmd(Cmd)),
    case Raw of
        <<""/utf8>> ->
            {lookup_error,
                <<"notion_cli produced no output for page "/utf8,
                    Page_id/binary>>};

        _ ->
            parse_princess_json(Raw)
    end.

-file("src/notion_harness.gleam", 95).
?DOC(
    " Like `find_princess_callout`, but requests `--all` from notion_cli so\n"
    " the returned `todos` include BOTH open and checked items (with\n"
    " `checked` reflecting their state). Use this in views that need to\n"
    " visualize completed todos alongside open ones.\n"
).
-spec find_princess_callout_all(binary()) -> princess_lookup().
find_princess_callout_all(Page_id) ->
    Cmd = <<<<"notion_cli princess "/utf8, (shell_quote(Page_id))/binary>>/binary,
        " --all --json 2>/dev/null"/utf8>>,
    Raw = gleam@string:trim(notion_harness_ffi:os_cmd(Cmd)),
    case Raw of
        <<""/utf8>> ->
            {lookup_error,
                <<"notion_cli produced no output for page "/utf8,
                    Page_id/binary>>};

        _ ->
            parse_princess_json(Raw)
    end.

-file("src/notion_harness.gleam", 117).
?DOC(
    " Shell out to `notion_cli title <page_id>` and return the page's title\n"
    " as `Some(title)`, or `None` when the page has no title, the CLI\n"
    " produces no output, or the lookup fails. Used by empress to render\n"
    " the page name in the browser tab `<title>`, falling back to the\n"
    " project path when this returns `None`.\n"
    "\n"
    " Synchronous: blocks the calling process for the duration of the\n"
    " Notion API round-trip. Acceptable here because the call only\n"
    " happens once per shell render (HTML page load), which already\n"
    " shells out to `notion_cli princess` for the open-todos panel.\n"
).
-spec fetch_page_title(binary()) -> gleam@option:option(binary()).
fetch_page_title(Page_id) ->
    Cmd = <<<<"notion_cli title "/utf8, (shell_quote(Page_id))/binary>>/binary,
        " 2>/dev/null"/utf8>>,
    Raw = gleam@string:trim(notion_harness_ffi:os_cmd(Cmd)),
    case Raw of
        <<""/utf8>> ->
            none;

        <<"untitled"/utf8>> ->
            none;

        T ->
            {some, T}
    end.

-file("src/notion_harness.gleam", 129).
?DOC(
    " Shell out to `notion_cli princess create <page_id>`; on success returns\n"
    " the newly created callout's block id.\n"
).
-spec create_princess_callout(binary()) -> {ok, binary()} | {error, binary()}.
create_princess_callout(Page_id) ->
    Cmd = <<<<"notion_cli princess create "/utf8,
            (shell_quote(Page_id))/binary>>/binary,
        " 2>&1"/utf8>>,
    Raw = gleam@string:trim(notion_harness_ffi:os_cmd(Cmd)),
    case Raw of
        <<""/utf8>> ->
            {error, <<"notion_cli produced no output"/utf8>>};

        _ ->
            case gleam_stdlib:string_starts_with(Raw, <<"error:"/utf8>>) of
                true ->
                    {error, Raw};

                false ->
                    case is_uuid_like(Raw) of
                        true ->
                            {ok, Raw};

                        false ->
                            {error,
                                <<"unexpected notion_cli output: "/utf8,
                                    Raw/binary>>}
                    end
            end
    end.

-file("src/notion_harness.gleam", 40).
-spec usage() -> binary().
usage() ->
    <<"notion_cli (on PATH). IDs: dashed or 32-hex, both work.

  fetch <page_id> [-o path] [--empress-only]   md dump; blocks tagged
      '[//]: # (notion_block_id: <ID>)' above each line. --empress-only
      skips ✅ done callout's contents. No path: prints to stdout.
  check <block_id> [--uncheck]        toggle to_do checked state.
  comment <page_id|--block ID> text   add comment; --block = inline on that block.
  checkmark ensure <page_id>          get-or-create ✅ done callout, prints id.
  checkmark move <block_id>           move checked to_do into ✅ callout, archive original.
  done <block_id>                     check + checkmark move, sugar for both.
  iframe <page_id> <url>  (embed)     append embed block, prints id.
  princess <page_id> [--json]         find 👸 callout + open to_do children.
  princess create <page_id>           create 👸 callout, prints id (appended at end).

WORKFLOW: fetch --empress-only -o page.md -> grep -B1 '^- \\[ \\]' for ids ->
comment --block ID \"Working on…\" -> implement/verify -> pass: comment
--block ID \"Done: …\" then `done ID`  |  fail: leave unchecked, comment
--block ID \"Blocked: …\"  |  unclear: comment question, leave unchecked.
Independent todos: parallel subagents, one per todo/cluster.

ENV: NOTION_TOKEN (required), NOTION_PAGE_ID, NOTION_API_VERSION.
Exit 0 ok, 1 error.
"/utf8>>.

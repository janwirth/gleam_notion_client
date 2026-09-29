-module(notion_harness_test).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "test/notion_harness_test.gleam").
-export([main/0, usage_not_empty_test/0, parse_missing_test/0, parse_found_test/0, parse_found_without_content_markdown_test/0, parse_found_with_depth_test/0, parse_garbage_test/0]).

-file("test/notion_harness_test.gleam", 4).
-spec main() -> nil.
main() ->
    gleeunit:main().

-file("test/notion_harness_test.gleam", 8).
-spec usage_not_empty_test() -> nil.
usage_not_empty_test() ->
    U = notion_harness:usage(),
    _assert_subject = <<""/utf8>>,
    case U /= _assert_subject of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"notion_harness_test"/utf8>>,
                function => <<"usage_not_empty_test"/utf8>>,
                line => 10,
                kind => binary_operator,
                operator => '!=',
                left => #{kind => expression,
                    value => U,
                    start => 201,
                    'end' => 202
                    },
                right => #{kind => literal,
                    value => _assert_subject,
                    start => 206,
                    'end' => 208
                    },
                start => 194,
                'end' => 208,
                expression_start => 201})
    end,
    nil.

-file("test/notion_harness_test.gleam", 14).
-spec parse_missing_test() -> nil.
parse_missing_test() ->
    Raw = <<"{\"status\":\"missing\"}"/utf8>>,
    _assert_subject = notion_harness:parse_princess_json(Raw),
    case _assert_subject =:= missing of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"notion_harness_test"/utf8>>,
                function => <<"parse_missing_test"/utf8>>,
                line => 16,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 296,
                    'end' => 335
                    },
                right => #{kind => literal,
                    value => missing,
                    start => 339,
                    'end' => 346
                    },
                start => 289,
                'end' => 346,
                expression_start => 296})
    end,
    nil.

-file("test/notion_harness_test.gleam", 20).
-spec parse_found_test() -> nil.
parse_found_test() ->
    Raw = <<<<"{\"status\":\"found\",\"callout_block_id\":\"c-1\","/utf8,
            "\"todos\":[{\"id\":\"t-1\",\"text\":\"first\",\"checked\":false}],"/utf8>>/binary,
        "\"content_markdown\":\"extra notes\"}"/utf8>>,
    _assert_subject = notion_harness:parse_princess_json(Raw),
    _assert_subject@1 = {found,
        <<"c-1"/utf8>>,
        [{princess_todo, <<"t-1"/utf8>>, <<"first"/utf8>>, false, 0}],
        <<"extra notes"/utf8>>},
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"notion_harness_test"/utf8>>,
                function => <<"parse_found_test"/utf8>>,
                line => 25,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 586,
                    'end' => 625
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 633,
                    'end' => 753
                    },
                start => 579,
                'end' => 753,
                expression_start => 586})
    end,
    nil.

-file("test/notion_harness_test.gleam", 36).
-spec parse_found_without_content_markdown_test() -> nil.
parse_found_without_content_markdown_test() ->
    Raw = <<"{\"status\":\"found\",\"callout_block_id\":\"c-1\","/utf8,
        "\"todos\":[{\"id\":\"t-1\",\"text\":\"first\",\"checked\":false}]}"/utf8>>,
    _assert_subject = notion_harness:parse_princess_json(Raw),
    _assert_subject@1 = {found,
        <<"c-1"/utf8>>,
        [{princess_todo, <<"t-1"/utf8>>, <<"first"/utf8>>, false, 0}],
        <<""/utf8>>},
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"notion_harness_test"/utf8>>,
                function => <<"parse_found_without_content_markdown_test"/utf8>>,
                line => 40,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 1101,
                    'end' => 1140
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 1148,
                    'end' => 1257
                    },
                start => 1094,
                'end' => 1257,
                expression_start => 1101})
    end,
    nil.

-file("test/notion_harness_test.gleam", 49).
-spec parse_found_with_depth_test() -> nil.
parse_found_with_depth_test() ->
    Raw = <<<<<<"{\"status\":\"found\",\"callout_block_id\":\"c-1\","/utf8,
                "\"todos\":[{\"id\":\"t-1\",\"text\":\"top\",\"checked\":false,\"depth\":0},"/utf8>>/binary,
            "{\"id\":\"t-2\",\"text\":\"sub\",\"checked\":false,\"depth\":2}],"/utf8>>/binary,
        "\"content_markdown\":\"\"}"/utf8>>,
    _assert_subject = notion_harness:parse_princess_json(Raw),
    _assert_subject@1 = {found,
        <<"c-1"/utf8>>,
        [{princess_todo, <<"t-1"/utf8>>, <<"top"/utf8>>, false, 0},
            {princess_todo, <<"t-2"/utf8>>, <<"sub"/utf8>>, false, 2}],
        <<""/utf8>>},
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"notion_harness_test"/utf8>>,
                function => <<"parse_found_with_depth_test"/utf8>>,
                line => 55,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 1581,
                    'end' => 1620
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 1628,
                    'end' => 1824
                    },
                start => 1574,
                'end' => 1824,
                expression_start => 1581})
    end,
    nil.

-file("test/notion_harness_test.gleam", 67).
-spec parse_garbage_test() -> nil.
parse_garbage_test() ->
    case notion_harness:parse_princess_json(<<"not json"/utf8>>) of
        {lookup_error, _} ->
            nil;

        _ ->
            erlang:error(#{gleam_error => panic,
                    message => <<"expected LookupError for garbage input"/utf8>>,
                    file => <<?FILEPATH/utf8>>,
                    module => <<"notion_harness_test"/utf8>>,
                    function => <<"parse_garbage_test"/utf8>>,
                    line => 70})
    end.

-module(notion_harness_ffi).
-export([os_cmd/1]).

os_cmd(Cmd) ->
    List = os:cmd(unicode:characters_to_list(Cmd)),
    unicode:characters_to_binary(List).

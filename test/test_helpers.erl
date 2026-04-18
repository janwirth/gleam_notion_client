%% Tiny FFI helpers for retry tests. The retry test stores its fake
%% response queue and slept-ms list in the process dictionary; these
%% helpers cast `gleam/dynamic.Dynamic` values back to their concrete
%% Erlang shapes so the Gleam test code can assert on them.

-module(test_helpers).
-export([as_response_script/1, as_int_list/1, to_int/1]).

as_response_script(V) -> V.
as_int_list(V) -> V.
to_int(V) -> V.

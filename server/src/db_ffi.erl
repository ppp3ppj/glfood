-module(db_ffi).
-export([priv_dir/0]).

priv_dir() ->
    erlang:list_to_binary(code:priv_dir(server)).

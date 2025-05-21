-module(helper_ffi).
-export([do_cmd/1]).

do_cmd(BinCommand) -> 
  CommandChars = binary_to_list(BinCommand),
  os:cmd(CommandChars).
import gleam/erlang/charlist.{type Charlist}
import gleam/int

// const mask32bit = 0xFFFFFFFF
const mask64bit = 0xFFFFFFFFFFFFFFFF

/// logic shift right
pub fn lsr(n: Int, bits: Int) -> Int {
  int.bitwise_shift_right(int.bitwise_and(n, mask64bit), bits)
}

/// logic shift left
pub fn lsl(n: Int, bits: Int) -> Int {
  int.bitwise_shift_left(int.bitwise_and(n, mask64bit), bits)
}

@external(erlang, "os", "cmd")
fn erl_cmd(command: Charlist) -> String

pub fn cmd(command: String) -> String {
  erl_cmd(charlist.from_string(command))
}

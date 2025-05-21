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

@external(erlang, "helper_ffi", "do_cmd")
@external(javascript, "./helper_ffi.mjs", "do_cmd")
fn do_cmd(command: String) -> String

pub fn cmd(command: String) -> String {
  do_cmd(command)
}

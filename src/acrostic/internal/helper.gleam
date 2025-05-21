import gleam/int

/// logic shift right
pub fn lsr(n: Int, bits: Int) -> Int {
  int.bitwise_shift_right(n, bits)
}

/// logic shift left
pub fn lsl(n: Int, bits: Int) -> Int {
  int.bitwise_shift_left(n, bits)
}

@external(erlang, "helper_ffi", "do_cmd")
@external(javascript, "./helper_ffi.mjs", "do_cmd")
fn do_cmd(command: String) -> String

pub fn cmd(command: String) -> String {
  do_cmd(command)
}

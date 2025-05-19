import acrostic
import acrostic/decoding
import acrostic/encoding
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  1
  |> should.equal(1)
}

pub fn pb_test() {
  acrostic.gen(
    ["game.proto"],
    to: "src/game.gleam",
    flags: acrostic.Flags(False, False),
  )
}

pub fn smaller_test() {
  encoding.encode_varint(137) |> decoding.to_varint(0) |> should.equal(137)
  encoding.encode_varint(123_456_789)
  |> decoding.to_varint(0)
  |> should.equal(123_456_789)
}

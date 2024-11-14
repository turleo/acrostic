import acrostic
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

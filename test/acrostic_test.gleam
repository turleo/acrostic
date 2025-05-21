import acrostic
import gleeunit

pub fn main() {
  gleeunit.main()
}

pub fn pb_test() {
  acrostic.gen(
    ["game.proto"],
    to: "src/game.gleam",
    flags: acrostic.Flags(False, False),
  )
}

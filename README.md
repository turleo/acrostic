# acrostic

[![Package Version](https://img.shields.io/hexpm/v/acrostic)](https://hex.pm/packages/acrostic)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/acrostic/)





```sh
gleam add acrostic
```
```gleam
import acrostic

pub fn main() {
  // TODO: An example of the project in use
  acrostic.gen(["game.proto"], to: "src/game.gleam", flags: acrostic.Flags(False, False))
}
```

Further documentation can be found at <https://hexdocs.pm/acrostic>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```

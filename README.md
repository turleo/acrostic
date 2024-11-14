# acrostic

[![Package Version](https://img.shields.io/hexpm/v/acrostic)](https://hex.pm/packages/acrostic)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/acrostic/)

A pure Gleam implementation of Google Protobuf.


Note:

1. only support proto3
2. only support enum, message, repeated
3. see `game.proto`


```sh
gleam add acrostic
```
```gleam
import acrostic

pub fn main() {
  acrostic.gen(["game.proto"], to: "src/game.gleam", flags: acrostic.Flags(False, False))
}
```

Further documentation can be found at <https://hexdocs.pm/acrostic>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```

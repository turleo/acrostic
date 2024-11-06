import pb/generator.{generate, load, shutdown}

pub fn main() {
  generator.start()
  |> load("protos/common.proto")
  |> load("protos/hello.proto")
  |> load("protos/lobby.proto")
  |> generate("src/proto.gleam")
  |> shutdown
}

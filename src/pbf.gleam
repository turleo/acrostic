import gleam/io
import pbf/generator.{generate, load, shutdown}

pub fn main() {
  io.println("Hello from pbf!")

  generator.start()
  |> load("protos/common.proto")
  |> load("protos/hello.proto")
  |> load("protos/lobby.proto")
  |> generate("src/proto.gleam")
  |> shutdown
}

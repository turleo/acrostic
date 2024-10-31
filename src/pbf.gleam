import gleam/io
import pbf/protogen.{generate, load, shutdown}

pub fn main() {
  io.println("Hello from pbf!")

  let assert Ok(generator) = protogen.start()
  let _ =
    generator
    |> load("protos/common.proto")
    |> load("protos/hello.proto")
    |> load("protos/lobby.proto")
    |> generate("src/proto.gleam")
    |> shutdown
}

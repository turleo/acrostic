import gleam/io
import gleam/list
import gleam/string
import pb/generator.{generate_proto}
import simplifile

pub fn gen(protos: List(String), to out_path: String) {
  protos
  |> list.map(fn(filepath) {
    case simplifile.read(from: filepath) {
      Ok(content) -> content
      Error(e) -> panic as string.inspect(e)
    }
  })
  |> list.fold("", string.append)
  |> generate_proto(out_path)

  io.println("done")
}

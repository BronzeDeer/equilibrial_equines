import gleam/list
import qcheck.{type Generator, bind, constant, list_from}

pub fn gen_recursive(
  leaf_gen: Generator(b),
  extend: fn(Generator(b)) -> Generator(b),
) -> Generator(b) {
  use num_extensions <- bind(list_from(constant(Nil)))

  num_extensions |> list.fold(leaf_gen, fn(x, _) { extend(x) })
}

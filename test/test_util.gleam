import gleam/dict.{type Dict}
import gleam/list
import gleam/pair
import gleam/result
import qcheck.{type Generator, bind, constant, list_from, map, return}
import tote/bag.{type Bag}
import util.{list_get_position}

pub fn gen_recursive(
  leaf_gen: Generator(b),
  extend: fn(Generator(b)) -> Generator(b),
) -> Generator(b) {
  use num_extensions <- bind(list_from(constant(Nil)))

  num_extensions |> list.fold(leaf_gen, fn(x, _) { extend(x) })
}

pub fn bag_from(g: Generator(a)) -> Generator(Bag(a)) {
  list_from(g) |> map(bag.from_list)
}

pub fn pick_from_list_uniform(l: List(a)) -> Result(Generator(a), Nil) {
  case l {
    [] -> Error(Nil)
    _ ->
      l
      |> list.length
      |> qcheck.bounded_int(0, _)
      |> map(list_get_position(l, _))
      |> map(result.lazy_unwrap(_, fn() { panic }))
      |> Ok
  }
}

pub fn pick_from_list_uniform_index(
  l: List(a),
) -> Result(Generator(#(Int, a)), Nil) {
  case l {
    [] -> Error(Nil)
    _ ->
      {
        use pos <- bind(
          l
          |> list.length
          |> qcheck.bounded_int(0, _),
        )
        pos
        |> list_get_position(l, _)
        |> result.map(pair.new(pos, _))
        |> result.lazy_unwrap(fn() { panic })
        |> return
      }
      |> Ok
  }
}

pub fn pick_key_uniform(d: Dict(member, _)) -> Result(Generator(member), Nil) {
  case d |> dict.size {
    0 -> Error(Nil)
    _ ->
      {
        use pos <- bind(qcheck.bounded_int(0, dict.size(d) - 1))

        d
        |> dict.keys
        |> list_get_position(pos)
        |> result.lazy_unwrap(fn() { panic })
        |> return
      }
      |> Ok
  }
}

pub fn lift_maybe_gen(
  g: Generator(Result(Generator(a), e)),
) -> Generator(Result(a, e)) {
  use r <- bind(g)
  case r {
    Error(e) -> e |> Error |> return
    Ok(inner_g) -> inner_g |> map(Ok)
  }
}

pub fn lift_gen_maybe(
  r: Result(Generator(Result(a, e)), e),
) -> Generator(Result(a, e)) {
  case r {
    Error(e) -> Error(e) |> return
    Ok(g) -> g
  }
}

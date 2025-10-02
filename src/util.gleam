import gleam/list
import gleam/pair
import gleam/result
import tote/bag.{type Bag}

pub fn bag_remove_or_error(b: Bag(a), member: a) -> Result(Bag(a), Nil) {
  case bag.contains(b, member) {
    True -> bag.remove(b, 1, member) |> Ok
    _ -> Error(Nil)
  }
}

pub fn just(val: a) -> fn(_) -> a {
  fn(_) { val }
}

pub fn constant(val: a) -> fn() -> a {
  fn() { val }
}

pub fn list_extract_position(
  list: List(member),
  pos: Int,
) -> Result(#(member, List(member)), Nil) {
  case list, pos {
    [head, ..tail], 0 -> Ok(#(head, tail))
    [head, ..tail], _ ->
      list_extract_position(tail, pos - 1)
      |> result.map(pair.map_second(_, list.prepend(_, head)))
    _, _ -> Error(Nil)
  }
}

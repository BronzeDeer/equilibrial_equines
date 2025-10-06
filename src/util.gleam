import gleam/dict
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

pub fn list_get_position(l: List(a), pos: Int) -> Result(a, Nil) {
  case l, pos {
    [head, ..], 0 -> Ok(head)
    [_, ..tail], _ if pos > 0 -> list_get_position(tail, pos - 1)
    _, _ -> Error(Nil)
  }
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

pub fn list_insert_position(
  l: List(member),
  pos: Int,
  value: member,
) -> Result(List(member), Nil) {
  case l, pos {
    [head, ..tail], _ ->
      list_insert_position(tail, pos - 1, value)
      |> result.map(list.prepend(_, head))
    _, 0 -> l |> list.prepend(value) |> Ok
    [], _ -> Error(Nil)
  }
}

pub fn bag_key_map(b: Bag(a), with: fn(a) -> b) -> Bag(b) {
  b
  |> bag.to_list
  |> list.map(pair.map_first(_, with))
  |> dict.from_list
  |> bag.from_map
}

// pub fn result_any(l: List(Result(a, b))) -> List(a) {
//   l
//   |> list.filter(result.is_ok)
//   |> list.map(result.lazy_unwrap(_, fn() { panic }))
// }

// pub type MaybeT(m, a) {
//   MaybeT(return: fn(a) -> m, fn(m(Result(a, e))) -> Result(a, e))
// }

// pub fn result_t(f: ) -> Result(T(a), e) {
//   todo
// }

pub fn list_pop_head(l: List(a)) -> Result(#(a, List(a)), Nil) {
  case l {
    [head, ..tail] -> Ok(#(head, tail))
    _ -> Error(Nil)
  }
}

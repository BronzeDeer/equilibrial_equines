import counting_set as cs
import gleam/int
import gleam/list
import gleam/result
import gleam/set
import gleeunit/should

import qcheck.{
  type Generator, bind, bool, generic_list, map, return,
  small_non_negative_int as nonneg_int, small_strictly_positive_int as pos_int,
  tuple2,
}

pub fn pick_from_list_multiple(list: List(member)) -> Generator(List(member)) {
  use #(pick, continue) <- bind(tuple2(bool(), bool()))

  case list, pick, continue {
    [head, ..tail], True, True ->
      pick_from_list_multiple(tail) |> map(list.prepend(_, head))
    [head, ..], True, False -> return([head])
    [_, ..tail], False, True -> pick_from_list_multiple(tail)
    _, _, _ -> return([])
  }
}

pub fn pick_from_list(list: List(member)) -> Generator(Result(member, Nil)) {
  use pick <- bind(bool())

  case list, pick {
    [head, ..], True -> head |> Ok |> return

    [head, ..tail], False -> {
      use tail_pick <- bind(pick_from_list(tail))
      case tail_pick {
        Ok(x) -> x |> Ok |> return
        Error(_) -> head |> Ok |> return
      }
    }
    _, _ -> Error(Nil) |> return
  }
}

pub fn generic_counting_set(elements_from, length_from) {
  qcheck.map(generic_list(elements_from, length_from), cs.from_list)
}

pub fn list_roundtrip_test() {
  use cset <- qcheck.given(generic_counting_set(pos_int(), nonneg_int()))

  should.equal(cset, cset |> cs.to_list |> cs.from_list)
}

pub fn set_roundtrip_test() {
  use set <- qcheck.given(qcheck.generic_set(pos_int(), nonneg_int()))
  should.equal(set, set |> set.to_list |> cs.from_list |> cs.to_key_set)
}

pub fn add_test() {
  use #(cset, to_add, num_add) <- qcheck.given(qcheck.tuple3(
    generic_counting_set(nonneg_int(), nonneg_int()),
    nonneg_int(),
    pos_int(),
  ))

  let target_count =
    cset
    |> cs.get(to_add)
    |> result.lazy_unwrap(fn() { 0 })
    |> int.add(num_add)

  let inserted = cset |> cs.insert_num(to_add, num_add)

  inserted
  |> cs.get(to_add)
  |> result.map(should.equal(target_count, _))
  |> should.be_ok
}

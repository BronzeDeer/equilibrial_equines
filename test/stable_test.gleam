import card_test.{unicorn_card_gen, up_down_card_gen}
import counting_set as cs
import gleam/list
import gleam/result
import gleeunit/should
import qcheck.{bind, generic_list, map, return, small_non_negative_int, tuple2}
import stable.{Stable}

import qcheck_gleeunit_utils/test_spec

pub fn stable_gen() {
  use #(unicorns, updowns) <- bind(tuple2(
    generic_list(unicorn_card_gen(), small_non_negative_int())
      |> map(cs.from_list),
    generic_list(up_down_card_gen(), small_non_negative_int())
      |> map(cs.from_list),
  ))

  Stable(unicorns, updowns) |> return
}

pub fn list_roundtrip_add_test() {
  use <- test_spec.make

  use stable <- qcheck.given(stable_gen())

  stable
  |> stable.to_card_list
  |> list.try_fold(stable.new(), stable.add_card)
  |> result.map(should.equal(stable, _))
  |> should.be_ok
}

pub fn list_roundtrip_remove_test() {
  use <- test_spec.make

  use stable <- qcheck.given(stable_gen())

  stable
  |> stable.to_card_list
  |> list.try_fold(stable, stable.remove_card)
  |> result.map(should.equal(stable.new(), _))
  |> should.be_ok
}

pub fn list_bag_equiv_test() {
  use <- test_spec.make

  use stable <- qcheck.given(stable_gen())

  stable
  |> stable.to_card_list
  |> cs.from_list
  |> should.equal(stable |> stable.stable_cards_to_card_set())
}

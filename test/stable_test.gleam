import card_test.{unicorn_card_gen, up_down_card_gen}
import gleam/list
import gleam/result
import gleeunit/should
import player.{type Stable}
import qcheck.{bind, generic_list, map, return, small_non_negative_int, tuple2}
import test_util

pub fn stable_gen() {
  card_test.stable_card_gen() |> test_util.bag_from
}

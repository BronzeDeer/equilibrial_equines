import card_test
import test_util

pub fn stable_gen() {
  card_test.stable_card_gen() |> test_util.bag_from
}

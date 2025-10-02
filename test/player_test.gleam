import card.{type UnicornCard}
import card_test.{
  magic_card_gen, magic_unicorn_gen, standard_unicorn_gen, ultimate_unicorn_gen,
  up_down_card_gen,
}
import player.{Player}
import qcheck.{
  type Generator, alphanumeric_ascii_codepoint, apply, bind, from_generators,
  given, map, map2, parameter, return, small_non_negative_int as nonneg_int,
  string_from,
}
import stable_test.{stable_gen}
import test_util

pub fn player_id_gen() {
  string_from(alphanumeric_ascii_codepoint())
}

pub fn player_gen() {
  return({
    use uuid <- parameter
    use hand <- parameter
    use stable <- parameter
    Player(uuid:, hand:, stable:)
  })
  |> apply(player_id_gen())
  |> apply(card_test.hand_pile_card_gen() |> test_util.bag_from)
  |> apply(stable_gen())
}

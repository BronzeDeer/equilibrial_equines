import card_test
import player.{Player}
import qcheck.{
  alphanumeric_ascii_codepoint, apply, parameter, return, string_from,
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

import card.{type Card, type UnicornCard}
import card_test.{
  magic_card_gen, magic_unicorn_gen, standard_unicorn_gen, ultimate_unicorn_gen,
  up_down_card_gen,
}
import counting_set_test.{generic_counting_set}
import player.{Player}
import qcheck.{
  type Generator, alphanumeric_ascii_codepoint, apply, bind, from_generators,
  given, map, map2, parameter, return, small_non_negative_int as nonneg_int,
  string_from,
}
import stable_test.{stable_gen}

pub fn player_id_gen() {
  string_from(alphanumeric_ascii_codepoint())
}

pub fn unicorn_hand_card_gen() -> Generator(UnicornCard) {
  from_generators(standard_unicorn_gen(), [
    magic_unicorn_gen(),
    ultimate_unicorn_gen(),
  ])
}

pub fn hand_card_gen() -> Generator(Card) {
  from_generators(unicorn_hand_card_gen() |> map(card.UC), [
    magic_card_gen() |> map(card.MC),
    up_down_card_gen() |> map(card.UD),
  ])
}

pub fn player_gen() {
  return({
    use uuid <- parameter
    use hand <- parameter
    use stable <- parameter
    Player(uuid:, hand:, stable:)
  })
  |> apply(player_id_gen())
  |> apply(generic_counting_set(hand_card_gen(), nonneg_int()))
  |> apply(stable_gen())
}

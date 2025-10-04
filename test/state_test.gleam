import card.{type BabyCard, type HandPileCard, BabyCard}
import card_test.{hand_pile_card_gen}
import gleam/dict
import gleam/int
import gleam/list
import gleam/pair
import player.{type Player, type Stable}
import player_test
import qcheck.{apply, bind, list_from, map, parameter, return}
import state.{type GameState, GameState}
import tote/bag.{type Bag}

pub fn state_gen() {
  use players <- bind(list_from(player_test.player_gen()))
  // qcheck doesn't have good strategies for generating fixed-size unique values, so we will cheat a bit by numbering our players sequentially
  let numbered_players =
    players
    |> list.length
    |> list.range(1, _)
    |> list.map(int.to_string)
    |> list.zip(players)
    |> dict.from_list
    |> dict.map_values(fn(key, p) { player.with_id(p, key) })

  return({
    use draw_pile <- parameter
    use discard_pile <- parameter
    use nursery <- parameter
    use players <- parameter
    GameState(draw_pile:, discard_pile:, nursery:, players:)
  })
  |> apply(list_from(hand_pile_card_gen()))
  |> apply(list_from(hand_pile_card_gen()))
  |> apply(list_from(qcheck.small_non_negative_int()) |> map(list.unique))
  |> apply(return(numbered_players))
}

pub fn total_cards_from_stable(
  stable: Stable,
) -> #(Bag(HandPileCard), Bag(BabyCard)) {
  stable
  |> bag.fold(#(bag.new(), bag.new()), fn(acc, card, _) {
    case card {
      card.StabledBaby(baby, _) ->
        acc |> pair.map_second(bag.insert(_, 1, baby))
      card.StabledUnicorn(card, _) ->
        acc |> pair.map_first(bag.insert(_, 1, card |> card.Unicorn))
      card.StabledUpDown(card:) ->
        acc |> pair.map_first(bag.insert(_, 1, card |> card.UpDown))
    }
  })
}

pub fn total_cards_from_player(
  player: Player,
) -> #(Bag(HandPileCard), Bag(BabyCard)) {
  player
  |> player.get_stable
  |> total_cards_from_stable
  |> pair.map_first(bag.merge(_, player.hand))
}

pub fn total_cards_from_state(
  state: GameState,
) -> #(Bag(HandPileCard), Bag(BabyCard)) {
  dict.fold(state.players, #(bag.new(), bag.new()), fn(acc, _, player) {
    let #(non_babies, babies) = total_cards_from_player(player)

    acc
    |> pair.map_first(bag.merge(_, non_babies))
    |> pair.map_second(bag.merge(_, babies))
  })
  |> pair.map_first(bag.merge(state.discard_pile |> bag.from_list, _))
  |> pair.map_first(bag.merge(state.draw_pile |> bag.from_list, _))
  |> pair.map_second(bag.merge(
    _,
    state.nursery |> list.map(BabyCard) |> bag.from_list,
  ))
}

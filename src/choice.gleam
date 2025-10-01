import card.{type HandPileCard}
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/set.{type Set}
import player.{type PlayerId, type Stable}
import tote/bag.{type Bag}

pub type Selection {
  HandPileSelection(num: Int, options: Bag(HandPileCard))
  CardsFromStableSelection(
    num: Int,
    options: Dict(PlayerId, Stable),
    from_same_stable: Bool,
  )
  PlayerSelection(num: Int, options: Set(PlayerId))
}

pub type Choice {
  HandPileCards(cards: Bag(HandPileCard))
  CardsFromStable(cards: Dict(PlayerId, Stable))
  Players(Set(PlayerId))
}

fn bag_total(bag: Bag(a)) -> Int {
  bag.fold(bag, 0, fn(acc, _, count) { int.add(count, acc) })
}

fn from_stable_correct_count(num: Int, choices: Dict(PlayerId, Stable)) -> Bool {
  let total =
    choices
    |> dict.values
    |> list.fold(0, fn(acc, stable_cards) {
      stable_cards |> bag_total |> int.add(acc)
    })
  num == total
}

fn from_stable_correct_subset(
  options: Dict(PlayerId, Stable),
  choices: Dict(PlayerId, Stable),
) -> Bool {
  choices
  |> dict.fold(True, fn(acc, pid, choice_set) {
    case options |> dict.get(pid) {
      Ok(option_set) ->
        // A intersect B == A <=> A subset B
        acc && bag.intersect(choice_set, option_set) == choice_set
      _ -> False
    }
  })
}

pub fn is_choice_valid(selection: Selection, choice: Choice) -> Bool {
  case selection, choice {
    CardSelection(num, options), Cards(cards) -> {
      let as_set = cards |> counting_set.from_list
      num == counting_set.size(as_set) && as_set |> is_subset(options)
    }
    CardsFromStableSelection(num, options, from_same_stable),
      CardsFromStable(cards)
    -> {
      let choice_sets =
        cards
        |> dict.map_values(fn(_, s) { stable.stable_cards_to_card_set(s) })

      let option_sets =
        options
        |> dict.map_values(fn(_, s) { stable.stable_cards_to_card_set(s) })

      { !from_same_stable || dict.size(cards) == 1 }
      && from_stable_correct_count(num, choice_sets)
      && from_stable_correct_subset(option_sets, choice_sets)
    }
    PlayerSelection(num, options), Players(choices) -> {
      num == set.size(choices) && choices |> set.is_subset(options)
    }
    _, _ -> False
  }
}

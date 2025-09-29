import card.{type Card}
import counting_set.{type CountingSet, is_subset}
import gleam/dict.{type Dict}
import gleam/list
import gleam/set.{type Set}
import player.{type PlayerId}
import stable.{type Stable}

pub type Selection {
  CardSelection(num: Int, options: CountingSet(Card))
  CardsFromStableSelection(
    num: Int,
    options: Dict(PlayerId, Stable),
    from_same_stable: Bool,
  )
  PlayerSelection(num: Int, options: Set(PlayerId))
}

pub type Choice {
  Cards(cards: List(Card))
  CardsFromStable(cards: Dict(PlayerId, Stable))
  Players(Set(PlayerId))
}

fn from_stable_correct_count(
  num: Int,
  choices: Dict(PlayerId, CountingSet(Card)),
) -> Bool {
  let total =
    choices
    |> dict.values
    |> list.fold(0, fn(acc, stable_cards) {
      acc + counting_set.total_count(stable_cards)
    })
  num == total
}

fn from_stable_correct_subset(
  options: Dict(PlayerId, CountingSet(Card)),
  choices: Dict(PlayerId, CountingSet(Card)),
) -> Bool {
  choices
  |> dict.fold(True, fn(acc, pid, choice_set) {
    case options |> dict.get(pid) {
      Ok(option_set) -> acc && choice_set |> counting_set.is_subset(option_set)
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

import card.{type Card, type UnicornCard, type UpDownCard}
import counting_set.{type CountingSet, map_keys, union}
import gleam/list
import gleam/result

pub type Stable {
  Stable(unicorns: CountingSet(UnicornCard), up_down: CountingSet(UpDownCard))
}

pub fn stable_cards_to_card_list(stable: Stable) -> List(card.Card) {
  list.append(
    stable.unicorns |> counting_set.to_list |> list.map(card.UC),
    stable.up_down |> counting_set.to_list |> list.map(card.UD),
  )
}

pub fn stable_cards_to_card_set(stable: Stable) -> CountingSet(Card) {
  union(map_keys(stable.unicorns, card.UC), map_keys(stable.up_down, card.UD))
}

pub fn with_unicorns(stable: Stable, cards: CountingSet(UnicornCard)) -> Stable {
  Stable(..stable, unicorns: cards)
}

pub fn with_updowns(stable, cards) -> Stable {
  Stable(..stable, up_down: cards)
}

pub fn add_card(stable: Stable, card: Card) -> Result(Stable, Card) {
  case card {
    card.UC(unicorn) -> {
      stable.unicorns
      |> counting_set.insert(unicorn)
      |> with_unicorns(stable, _)
      |> Ok
    }
    card.UD(updown) -> {
      stable.up_down
      |> counting_set.delete_or_error(updown)
      |> result.map_error(card.UD)
      |> result.map(with_updowns(stable, _))
    }
    _ -> Error(card)
  }
}

pub fn remove_card(stable: Stable, card: Card) -> Result(Stable, Card) {
  case card {
    card.UC(unicorn) -> {
      stable.unicorns
      |> counting_set.delete_or_error(unicorn)
      |> result.map_error(card.UC)
      |> result.map(fn(x) { Stable(..stable, unicorns: x) })
    }
    card.UD(updown) -> {
      stable.up_down
      |> counting_set.delete_or_error(updown)
      |> result.map_error(card.UD)
      |> result.map(fn(x) { Stable(..stable, up_down: x) })
    }
    _ -> Error(card)
  }
}

import card.{type Card, type UnicornCard, type UpDownCard}
import counting_set.{type CountingSet, map_keys, union}
import gleam/list

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

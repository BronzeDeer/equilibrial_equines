import card.{type UnicornCard, type UpDownCard}
import gleam/list

pub type Stable {
  Stable(unicorns: List(UnicornCard), up_down: List(UpDownCard))
}

pub fn stable_cards_to_card_list(stable: Stable) -> List(card.Card) {
  list.append(
    list.map(stable.unicorns, card.UC),
    list.map(stable.up_down, card.UD),
  )
}

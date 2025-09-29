import card
import equilibrial_equines.{type Player}

pub type Selection {
  CardSelection(num: Int, List(card.Card))
  CardsFromStableSelection(num: Int, target: Player, from_same_stable: Bool)
  PlayerSelection(num: Int, List(Player))
}

pub type Choice {
  Cards(selection: CardSelection, cards: List(card.Card))
  CardsFromStable(selection: CardsFromStableSelection, cards: List(Player))
  Players(selection: PlayerSelection, List(Player))
}

pub fn is_choice_valid(choice: Choice) -> Bool {
  case choice {
    Cards(selection,cards) -> // Todo: create counting set and make subsetting easier
  }
}

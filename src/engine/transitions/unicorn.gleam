import card.{type UnicornCard}
import engine/transitions/from_to.{
  type PileFromTo, type PlayerHandFromTo, type PlayerStableFromTo,
}

pub type UnicornSpot {
  Hand(PlayerHandFromTo)
  Pile(PileFromTo)
  Stable(PlayerStableFromTo, state: card.UnicornStableStatus)
}

pub type UnicornTransition {
  UnicornTransition(from: UnicornSpot, card: UnicornCard, to: UnicornSpot)
}

pub fn invert(t: UnicornTransition) {
  UnicornTransition(t.to, t.card, t.from)
}

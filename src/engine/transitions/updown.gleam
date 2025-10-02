import card.{type UpDownCard}
import engine/transitions/from_to.{
  type PileFromTo, type PlayerHandFromTo, type PlayerStableFromTo,
}

pub type UpDownSpot {
  Hand(PlayerHandFromTo)
  Pile(PileFromTo)
  Stable(PlayerStableFromTo)
}

pub type UpDownTransition {
  UpDownTransition(from: UpDownSpot, card: UpDownCard, to: UpDownSpot)
}

pub fn invert(t: UpDownTransition) {
  UpDownTransition(t.to, t.card, t.from)
}

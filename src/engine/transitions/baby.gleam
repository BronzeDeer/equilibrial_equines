import card.{type BabyCard}
import engine/transitions/from_to.{type PlayerStableFromTo}

pub type BabySpot {
  Stable(PlayerStableFromTo, card.UnicornStableStatus)
  Nursery
}

pub type BabyTransition {
  BabyTransition(from: BabySpot, card: BabyCard, to: BabySpot)
}

pub fn invert(t: BabyTransition) {
  BabyTransition(t.to, t.card, t.from)
}

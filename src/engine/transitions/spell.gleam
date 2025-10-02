import card.{type SpellCard}
import engine/transitions/from_to.{type PileFromTo, type PlayerHandFromTo}

pub type SpellSpot {
  Hand(PlayerHandFromTo)
  Pile(PileFromTo)
}

pub type SpellTransition {
  SpellTransition(from: SpellSpot, card: SpellCard, to: SpellSpot)
}

pub fn invert(t: SpellTransition) {
  SpellTransition(t.to, t.card, t.from)
}

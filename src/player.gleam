import card.{type Card}
import counting_set.{type CountingSet}
import stable

pub type PlayerId =
  String

pub type Player {
  Player(uuid: PlayerId, hand: CountingSet(Card), stable: stable.Stable)
}

pub type PlayerFilter {
  Not(Player)
  AnyPlayer
}

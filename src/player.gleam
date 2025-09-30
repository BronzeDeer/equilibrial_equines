import card.{type Card}
import counting_set.{type CountingSet}
import stable.{type Stable}

pub type PlayerId =
  String

pub type Player {
  Player(uuid: PlayerId, hand: CountingSet(Card), stable: Stable)
}

pub fn get_hand(player: Player) -> CountingSet(Card) {
  player.hand
}

pub fn with_hand(player: Player, hand: CountingSet(Card)) -> Player {
  Player(..player, hand: hand)
}

pub fn with_stable(player: Player, stable: Stable) -> Player {
  Player(..player, stable: stable)
}

pub type PlayerFilter {
  Not(Player)
  AnyPlayer
}

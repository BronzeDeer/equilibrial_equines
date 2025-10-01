import card.{type HandPileCard, type StableCard}
import counting_set.{type CountingSet}
import tote/bag.{type Bag}

pub type PlayerId =
  String

pub type PlayerHand =
  Bag(HandPileCard)

pub type Stable =
  Bag(StableCard)

pub type Player {
  Player(uuid: PlayerId, hand: PlayerHand, stable: Stable)
}

pub fn get_hand(player: Player) -> PlayerHand {
  player.hand
}

pub fn with_hand(player: Player, hand: PlayerHand) -> Player {
  Player(..player, hand: hand)
}

pub fn with_stable(player: Player, stable: Stable) -> Player {
  Player(..player, stable: stable)
}

pub type PlayerFilter {
  Not(Player)
  AnyPlayer
}

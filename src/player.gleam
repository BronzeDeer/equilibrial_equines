import card.{type HandPileCard, type StableCard}
import counting_set.{type CountingSet}
import gleam/result
import tote/bag.{type Bag}
import util.{bag_remove_or_error}

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

pub fn remove_hand_card(
  player: Player,
  card: HandPileCard,
) -> Result(Player, Nil) {
  player.hand
  |> bag_remove_or_error(card)
  |> result.map(with_hand(player, _))
}

pub fn remove_stable_card(
  player: Player,
  card: StableCard,
) -> Result(Player, Nil) {
  player.stable
  |> bag_remove_or_error(card)
  |> result.map(with_stable(player, _))
}

pub type PlayerFilter {
  Not(Player)
  AnyPlayer
}

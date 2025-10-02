import player.{type PlayerId}

pub type PileFromTo {
  // Remember position to maintain invertability
  // 0 is the head of the pile
  Draw(pos: Int)
  Discard(pos: Int)
}

pub type PlayerHandFromTo {
  PlayerHandFromTo(id: PlayerId)
}

pub type PlayerStableFromTo {
  PlayerStableFromTo(id: PlayerId)
}

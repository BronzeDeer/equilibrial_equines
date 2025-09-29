import card.{type Card}
import gleam/io
import player.{type Player}

pub type Game {
  Game(state: GameState)
}

pub type Pile =
  List(Card)

pub type GameState {
  GameState(
    draw_pile: Pile,
    discard_pile: Pile,
    nursery: List(Int),
    players: List(Player),
    // Todo: How to do define non-empty list
  )
}

pub fn main() -> Nil {
  io.println("Hello from equilibrial_equines!")
}

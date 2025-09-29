import card.{type Card}
import gleam/dict.{type Dict}
import gleam/io
import player.{type Player, type PlayerId}

pub type Game {
  Game(state: GameState)
}

pub type DrawPile =
  List(Card)

pub type DiscardPile =
  List(Card)

pub type Pile {
  Draw(DrawPile)
  Discard(DiscardPile)
}

pub type GameState {
  GameState(
    draw_pile: DrawPile,
    discard_pile: DiscardPile,
    nursery: List(Int),
    players: Dict(PlayerId, Player),
    // Todo: How to do define non-empty list
  )
}

pub fn main() -> Nil {
  io.println("Hello from equilibrial_equines!")
}

import card.{type Card}
import engine.{type CardMovementFrom}
import equilibrial_equines.{type GameState} as ee
import qcheck.{
  type Generator, apply, bind, from_generators, given, map, map2, parameter,
  return,
}

pub fn valid_from_gen(
  state: GameState,
) -> Result(Generator(#(CardMovementFrom, Card)), Nil) {
  todo
}

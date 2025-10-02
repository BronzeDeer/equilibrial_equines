import card.{type HandPileCard}
import gleam/dict.{type Dict}
import gleam/result
import player.{type Player, type PlayerId}

pub type Game {
  Game(state: GameState)
}

pub type DrawPile =
  List(HandPileCard)

pub type DiscardPile =
  List(HandPileCard)

pub type Nursery =
  List(Int)

pub type Pile {
  Draw(DrawPile)
  Discard(DiscardPile)
}

pub type GameState {
  GameState(
    draw_pile: DrawPile,
    discard_pile: DiscardPile,
    nursery: Nursery,
    players: Dict(PlayerId, Player),
  )
}

pub fn with_draw_pile(state: GameState, pile: DrawPile) -> GameState {
  GameState(..state, draw_pile: pile)
}

pub fn with_discard_pile(state: GameState, pile: DiscardPile) -> GameState {
  GameState(..state, discard_pile: pile)
}

pub fn with_nursery(state, nursery: Nursery) -> GameState {
  GameState(..state, nursery: nursery)
}

pub fn with_player(state: GameState, player: Player) -> GameState {
  GameState(..state, players: state.players |> dict.insert(player.uuid, player))
}

pub fn with_existing_player(
  state: GameState,
  player: Player,
) -> Result(GameState, Player) {
  state.players
  |> dict.get(player.uuid)
  |> result.map_error(fn(_) { player })
  |> result.map(fn(_) { with_player(state, player) })
}

pub fn get_player(state: GameState, pid: PlayerId) -> Result(Player, PlayerId) {
  state.players |> dict.get(pid) |> result.map_error(fn(_) { pid })
}

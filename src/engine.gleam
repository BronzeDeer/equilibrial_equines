import card.{type Card}
import counting_set as cs
import equilibrial_equines.{type GameState, type Pile, GameState} as ee
import gleam/dict
import gleam/list
import gleam/result.{map_error, try}
import player.{type Player, type PlayerId, Player}
import stable

pub type StateTransition {
  Play(player: PlayerId, card: Card)
  Discard(player: PlayerId, card: Card)
  // Generic Action for stable to discard (Sac and Destroy)
  Destroy(player: PlayerId, card: Card)
  Draw(player: PlayerId)
  Search(player: PlayerId, card: Card, pile: Pile)
  Bounce(player: PlayerId, card: Card)
  //Neigh(player: PlayerId, card: Card, transition: StateTransition)
}

pub type InvalidTransition {
  InvalidTransition(state: GameState, trans: StateTransition)
  EmptyDrawPile
  CardNotInPile(card: Card, pile: Pile)
  NoSuchPlayer(player: PlayerId)
  CardNotInStable(card: Card, player: Player)
}

fn remove_first(list: List(member), value: member) -> Result(List(member), Nil) {
  case list {
    [head, ..tail] if value == head -> Ok(tail)
    [head, ..tail] ->
      remove_first(tail, value) |> result.map(list.prepend(_, head))
    _ -> Error(Nil)
  }
}

fn apply_draw(
  state: GameState,
  pid: PlayerId,
) -> Result(GameState, InvalidTransition) {
  use player <- try(
    state.players
    |> dict.get(pid)
    |> map_error(fn(_) { NoSuchPlayer(pid) }),
  )

  case state.draw_pile {
    [head, ..tail] -> {
      let p_prime = Player(..player, hand: player.hand |> cs.insert(head))

      GameState(
        ..state,
        draw_pile: tail,
        players: state.players |> dict.insert(pid, p_prime),
      )
      |> Ok
    }
    _ -> Error(EmptyDrawPile)
  }
}

fn apply_destroy(
  state: GameState,
  pid: PlayerId,
  card: Card,
) -> Result(GameState, InvalidTransition) {
  use player <- try(
    state.players
    |> dict.get(pid)
    |> map_error(fn(_) { NoSuchPlayer(pid) }),
  )

  use p_prime <- try(
    player.stable
    |> stable.remove_card(card)
    |> map_error(fn(_) { CardNotInStable(card, player) })
    |> result.map(fn(x) { Player(..player, stable: x) }),
  )

  GameState(
    ..state,
    discard_pile: state.discard_pile |> list.prepend(card),
    players: state.players |> dict.insert(pid, p_prime),
  )
  |> Ok
}

fn apply_bounce(
  state: GameState,
  pid: PlayerId,
  card: Card,
) -> Result(GameState, InvalidTransition) {
  use player <- try(
    state.players
    |> dict.get(pid)
    |> map_error(fn(_) { NoSuchPlayer(pid) }),
  )

  use p_prime <- try(
    player.stable
    |> stable.remove_card(card)
    |> map_error(fn(_) { CardNotInStable(card, player) })
    |> result.map(fn(x) {
      Player(..player, hand: player.hand |> cs.insert(card), stable: x)
    }),
  )

  GameState(..state, players: state.players |> dict.insert(pid, p_prime))
  |> Ok
}

fn apply_search(
  state: GameState,
  pid: PlayerId,
  card: Card,
  pile: Pile,
) -> Result(GameState, InvalidTransition) {
  use player <- try(
    state.players
    |> dict.get(pid)
    |> map_error(fn(_) { NoSuchPlayer(pid) }),
  )

  let p_prime = Player(..player, hand: player.hand |> cs.insert(card))

  case pile {
    ee.Draw(dp) ->
      dp
      |> remove_first(card)
      |> map_error(fn(_) { CardNotInPile(card, pile) })
      |> result.map(fn(x) {
        GameState(
          ..state,
          players: state.players |> dict.insert(pid, p_prime),
          draw_pile: x,
        )
      })

    ee.Discard(dp) ->
      dp
      |> remove_first(card)
      |> map_error(fn(_) { CardNotInPile(card, pile) })
      |> result.map(fn(x) {
        GameState(
          ..state,
          players: state.players |> dict.insert(pid, p_prime),
          discard_pile: x,
        )
      })
  }
}

pub fn apply(
  state: GameState,
  trans: StateTransition,
) -> Result(GameState, InvalidTransition) {
  case trans {
    Draw(pid) -> apply_draw(state, pid)
    Destroy(pid, card) -> apply_destroy(state, pid, card)
    Bounce(pid, card) -> apply_bounce(state, pid, card)
    Search(pid, card, pile) -> apply_search(state, pid, card, pile)
    _ -> Error(InvalidTransition(state, trans))
  }
}

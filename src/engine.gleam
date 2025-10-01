import card.{type Card, BabyUnicorn, UnicornCard}
import counting_set as cs
import equilibrial_equines.{type GameState, type Pile, GameState} as ee
import gleam/dict
import gleam/list
import gleam/result.{map_error, try}
import player.{type Player, type PlayerId, Player}
import stable

pub type UnicornSpot {
  Hand(PlayerHandFromTo)
  Pile(PileFromTo)
  Stable(PlayerStableFromTo)
}

pub type PileFromTo {
  Draw
  Discard
}

pub type PlayerHandFromTo {
  PlayerHandFromTo(id: PlayerId)
}

pub type PlayerStableFromTo {
  PlayerStableFromTo(id: PlayerId)
}

pub type SpellSpot {
  Hand(PlayerHandFromTo)
  Pile(PileFromTo)
}

pub type BabySpot {
  Stable(PlayerStableFromTo)
  Nursery
}

pub type UpDownSpot {
  Hand(PlayerHandFromTo)
  Pile(PileFromTo)
  Stable(PlayerStableFromTo)
}

pub type UnicornTransition {
  UnicornTransition(from: UnicornSpot, card: UnicornCard, to: UnicornSpot)
}

pub type UpDownTransition {
  UpDownTransition(from: UpDownSpot, card: UpDownCard, to: UpDownSpot)
}

pub type SpellTransition {
  SpellTransition(from: SpellSpot, card: SpellCard, to: SpellSpot)
}

pub type BabyTransition {
  BabyTransition(from: BabySpot, card: BabyCard, to: BabySpot)
}

pub type StateTransition

// pub type StateTransition {
//   Play(player: PlayerId, card: Card)
//   Discard(player: PlayerId, card: Card)
//   // Generic Action for stable to discard (Sac and Destroy)
//   Destroy(player: PlayerId, card: Card)
//   Draw(player: PlayerId)
//   Search(player: PlayerId, card: Card, pile: Pile)
//   Bounce(player: PlayerId, card: Card)
//   //Neigh(player: PlayerId, card: Card, transition: StateTransition)
//   // Todo: Pile shuffling
// }

pub type InvalidTransition {
  InvalidTransition(state: GameState, trans: StateTransition)
  EmptyDrawPile
  CardNotInPile(card: Card, pile: Pile)
  NoSuchPlayer(player: PlayerId)
  CardNotInStable(card: Card, player: Player)
  CardNotInHand(card: Card, player: Player)
  BabyNotFrontOfNursery(card: Card, front: Int)
  BabyFromToPile(card: Card, pile: Pile)
  BabyFromToHand(card: Card, pid: PlayerId)
  NotABaby(card: Card)
  NotAStableCard(card: Card)
}

fn remove_first(list: List(member), value: member) -> Result(List(member), Nil) {
  case list {
    [head, ..tail] if value == head -> Ok(tail)
    [head, ..tail] ->
      remove_first(tail, value) |> result.map(list.prepend(_, head))
    _ -> Error(Nil)
  }
}

// Atm there are not effects that generate cards or tokens from thin air, therefore there is a conservation of cards
// We can enfore the correctness of this via the data modell
// A card can exist in only a few places (either pile, the nursery, each player's hand, or each player's stable)

pub type CardMovementFrom {
  FromNursery
  FromPile(pile: Pile)
  FromHand(pid: PlayerId)
  FromStable(pid: PlayerId)
}

pub type CardMovementTo {
  ToNursery
  ToPile(pile: Pile)
  ToHand(pid: PlayerId)
  ToStable(pid: PlayerId)
}

pub type CardMovement {
  CardMovement(card: Card, from: CardMovementFrom, to: CardMovementTo)
}

fn invert_from(from: CardMovementFrom) -> CardMovementTo {
  case from {
    FromNursery -> ToNursery
    FromPile(p) -> ToPile(p)
    FromHand(p) -> ToHand(p)
    FromStable(p) -> ToStable(p)
  }
}

fn invert_to(to: CardMovementTo) -> CardMovementFrom {
  case to {
    ToNursery -> FromNursery
    ToPile(p) -> FromPile(p)
    ToHand(p) -> FromHand(p)
    ToStable(p) -> FromStable(p)
  }
}

pub fn invert_movement(move: CardMovement) -> CardMovement {
  CardMovement(move.card, invert_to(move.to), invert_from(move.from))
}

fn apply_from(
  state: GameState,
  card: Card,
  from: CardMovementFrom,
) -> Result(GameState, InvalidTransition) {
  case from {
    FromNursery -> from_nursery(state, card)
    FromPile(pile) -> from_pile(state, card, pile)
    FromHand(pid) -> from_hand(state, card, pid)
    FromStable(pid) -> from_stable(state, card, pid)
  }
}

fn apply_to(
  state: GameState,
  card: Card,
  to: CardMovementTo,
) -> Result(GameState, InvalidTransition) {
  case to {
    ToNursery -> to_nursery(state, card)
    ToPile(pile) -> to_pile(state, card, pile)
    ToHand(pid) -> to_hand(state, card, pid)
    ToStable(pid) -> to_stable(state, card, pid)
  }
}

fn from_nursery(
  state: GameState,
  card: Card,
) -> Result(GameState, InvalidTransition) {
  case card, state.nursery {
    card.UC(UnicornCard(_, body: BabyUnicorn(id1))), [id2, ..tail]
      if id1 == id2
    -> GameState(..state, nursery: tail) |> Ok
    card.UC(UnicornCard(_, body: BabyUnicorn(_))), [id, ..] ->
      BabyNotFrontOfNursery(card, id) |> Error
    _, _ -> NotABaby(card) |> Error
  }
}

fn to_nursery(
  state: GameState,
  card: Card,
) -> Result(GameState, InvalidTransition) {
  case card, state.nursery {
    card.UC(UnicornCard(_, body: BabyUnicorn(id))), nurse ->
      GameState(..state, nursery: [id, ..nurse]) |> Ok
    _, _ -> NotABaby(card) |> Error
  }
}

fn from_pile(
  state: GameState,
  card: Card,
  pile: Pile,
) -> Result(GameState, InvalidTransition) {
  case card, pile {
    card.UC(UnicornCard(_, body: BabyUnicorn(_))), _ ->
      BabyFromToPile(card, pile) |> Error
    _, ee.Draw(_) ->
      state.draw_pile
      |> remove_first(card)
      |> map_error(fn(_) { BabyFromToPile(card, pile) })
      |> result.map(fn(p) { GameState(..state, draw_pile: p) })
    _, ee.Discard(_) ->
      state.discard_pile
      |> remove_first(card)
      |> map_error(fn(_) { BabyFromToPile(card, pile) })
      |> result.map(fn(p) { GameState(..state, discard_pile: p) })
  }
}

fn to_pile(
  state: GameState,
  card: Card,
  pile: Pile,
) -> Result(GameState, InvalidTransition) {
  case card, pile {
    card.UC(UnicornCard(_, body: BabyUnicorn(_))), _ ->
      BabyFromToPile(card, pile) |> Error
    _, ee.Draw(_) ->
      GameState(
        ..state,
        draw_pile: state.draw_pile
          |> list.prepend(card),
      )
      |> Ok
    _, ee.Discard(_) ->
      GameState(
        ..state,
        discard_pile: state.discard_pile
          |> list.prepend(card),
      )
      |> Ok
  }
}

fn from_hand(
  state: GameState,
  card: Card,
  pid: PlayerId,
) -> Result(GameState, InvalidTransition) {
  case card {
    card.UC(UnicornCard(_, body: BabyUnicorn(_))) ->
      BabyFromToHand(card, pid) |> Error
    _ -> {
      use player <- try(state |> ee.get_player(pid) |> map_error(NoSuchPlayer))

      player.hand
      |> cs.delete_or_error(card)
      |> map_error(CardNotInHand(_, player))
      |> result.map(player.with_hand(player, _))
      |> result.map(ee.with_player(state, _))
    }
  }
}

fn to_hand(
  state: GameState,
  card: Card,
  pid: PlayerId,
) -> Result(GameState, InvalidTransition) {
  case card {
    card.UC(UnicornCard(_, body: BabyUnicorn(_))) ->
      BabyFromToHand(card, pid) |> Error
    _ -> {
      use player <- try(state |> ee.get_player(pid) |> map_error(NoSuchPlayer))

      player.hand
      |> cs.insert(card)
      |> player.with_hand(player, _)
      |> ee.with_player(state, _)
      |> Ok
    }
  }
}

fn from_stable(
  state: GameState,
  card: Card,
  pid: PlayerId,
) -> Result(GameState, InvalidTransition) {
  use player <- try(state |> ee.get_player(pid) |> map_error(NoSuchPlayer))

  player.stable
  |> stable.remove_card(card)
  |> map_error(CardNotInStable(_, player))
  |> result.map(player.with_stable(player, _))
  |> result.map(ee.with_player(state, _))
}

fn to_stable(
  state: GameState,
  card: Card,
  pid: PlayerId,
) -> Result(GameState, InvalidTransition) {
  use player <- try(state |> ee.get_player(pid) |> map_error(NoSuchPlayer))

  player.stable
  |> stable.add_card(card)
  |> map_error(NotAStableCard)
  |> result.map(player.with_stable(player, _))
  |> result.map(ee.with_player(state, _))
}

fn apply_movement(
  state: GameState,
  move: CardMovement,
) -> Result(GameState, InvalidTransition) {
  state
  |> apply_from(move.card, move.from)
  |> result.try(apply_to(_, move.card, move.to))
}

import card.{type BabyCard, type HandPileCard, type StableCard}
import engine/transitions/from_to
import gleam/list
import gleam/result.{map_error, try}
import player.{type Player, type PlayerId}
import state.{type GameState, type Pile}
import tote/bag
import util.{just}

import engine/transitions/baby.{type BabyTransition}
import engine/transitions/spell.{type SpellTransition}
import engine/transitions/unicorn.{type UnicornTransition}
import engine/transitions/updown.{type UpDownTransition}

// This is a low level engine which enforces correct card placement and movement through typing
// Higher level effects and actions can then easily be translated down to a sequence of these state transitions

pub type StateTransition {
  StateTransBaby(BabyTransition)
  StateTransSpell(SpellTransition)
  StateTransUpDown(UpDownTransition)
  StateTransUnicorn(UnicornTransition)
}

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
  CardNotInPileAtPosition(card: HandPileCard, pile: Pile, pos: Int)
  PilePositionOutOfBounds(pile: Pile, pos: Int)
  NoSuchPlayer(player: PlayerId)
  CardNotInStable(card: StableCard, player: Player)
  CardNotInHand(card: HandPileCard, player: Player)
  EmptyNursery
  NotNextBaby(card: BabyCard)
}

fn apply_from(
  state: GameState,
  trans: StateTransition,
) -> Result(GameState, InvalidTransition) {
  case trans {
    StateTransUnicorn(t) -> {
      case t.from {
        unicorn.Hand(from) -> from_hand(state, card.Unicorn(t.card), from)
        unicorn.Pile(from) -> from_pile(state, card.Unicorn(t.card), from)
        unicorn.Stable(from, status) ->
          from_stable(state, card.StabledUnicorn(t.card, status), from)
      }
    }
    StateTransBaby(t) ->
      case t.from {
        baby.Stable(from, status) ->
          from_stable(state, card.StabledBaby(t.card, status), from)
        baby.Nursery -> from_nursery(state, t.card)
      }
    StateTransSpell(t) ->
      case t.from {
        spell.Hand(from) -> from_hand(state, card.Spell(t.card), from)
        spell.Pile(from) -> from_pile(state, card.Spell(t.card), from)
      }
    StateTransUpDown(t) ->
      case t.from {
        updown.Hand(from) -> from_hand(state, card.UpDown(t.card), from)
        updown.Pile(from) -> from_pile(state, card.UpDown(t.card), from)
        updown.Stable(from) ->
          from_stable(state, card.StabledUpDown(t.card), from)
      }
  }
}

fn apply_to(
  state: GameState,
  trans: StateTransition,
) -> Result(GameState, InvalidTransition) {
  case trans {
    StateTransUnicorn(t) -> {
      case t.to {
        unicorn.Hand(to) -> to_hand(state, card.Unicorn(t.card), to.id)
        unicorn.Pile(to) -> to_pile(state, card.Unicorn(t.card), to)
        unicorn.Stable(to, status) ->
          to_stable(state, card.StabledUnicorn(t.card, status), to.id)
      }
    }
    StateTransBaby(t) ->
      case t.to {
        baby.Stable(to, status) ->
          to_stable(state, card.StabledBaby(t.card, status), to.id)
        baby.Nursery -> to_nursery(state, t.card)
      }
    StateTransSpell(t) ->
      case t.to {
        spell.Hand(to) -> to_hand(state, card.Spell(t.card), to.id)
        spell.Pile(to) -> to_pile(state, card.Spell(t.card), to)
      }
    StateTransUpDown(t) ->
      case t.to {
        updown.Hand(to) -> to_hand(state, card.UpDown(t.card), to.id)
        updown.Pile(to) -> to_pile(state, card.UpDown(t.card), to)
        updown.Stable(to) -> to_stable(state, card.StabledUpDown(t.card), to.id)
      }
  }
}

fn from_nursery(
  state: GameState,
  baby: BabyCard,
) -> Result(GameState, InvalidTransition) {
  case state.nursery {
    [head, ..tail] if head == baby.id -> state |> state.with_nursery(tail) |> Ok
    [_, ..] -> NotNextBaby(baby) |> Error
    _ -> EmptyNursery |> Error
  }
}

fn to_nursery(
  state: GameState,
  card: BabyCard,
) -> Result(GameState, InvalidTransition) {
  state.nursery |> list.prepend(card.id) |> state.with_nursery(state, _) |> Ok
}

fn from_pile(
  state: GameState,
  card: HandPileCard,
  from: from_to.PileFromTo,
) -> Result(GameState, InvalidTransition) {
  case from {
    from_to.Draw(pos) -> {
      use #(drawn, new_pile) <- result.try(
        state.draw_pile
        |> util.list_extract_position(pos)
        |> map_error(
          util.just({
            CardNotInPileAtPosition(card, state.Draw(state.draw_pile), pos)
          }),
        ),
      )
      case drawn == card {
        True -> state |> state.with_draw_pile(new_pile) |> Ok
        _ ->
          CardNotInPileAtPosition(card, state.Draw(state.draw_pile), pos)
          |> Error
      }
    }
    from_to.Discard(pos) -> {
      use #(drawn, new_pile) <- result.try(
        state.discard_pile
        |> util.list_extract_position(pos)
        |> map_error(
          util.just({
            CardNotInPileAtPosition(
              card,
              state.Discard(state.discard_pile),
              pos,
            )
          }),
        ),
      )
      case drawn == card {
        True -> state |> state.with_discard_pile(new_pile) |> Ok
        _ ->
          CardNotInPileAtPosition(card, state.Discard(state.discard_pile), pos)
          |> Error
      }
    }
  }
}

fn to_pile(
  state: GameState,
  card: HandPileCard,
  to: from_to.PileFromTo,
) -> Result(GameState, InvalidTransition) {
  case to {
    from_to.Draw(pos) ->
      state.draw_pile
      |> util.list_insert_position(pos, card)
      |> map_error(
        just(PilePositionOutOfBounds(state.Draw(state.draw_pile), pos)),
      )
      |> result.map(state.with_draw_pile(state, _))
    from_to.Discard(pos) ->
      state.discard_pile
      |> util.list_insert_position(pos, card)
      |> map_error(
        just(PilePositionOutOfBounds(state.Discard(state.discard_pile), pos)),
      )
      |> result.map(state.with_discard_pile(state, _))
  }
}

fn from_hand(
  state: GameState,
  card: HandPileCard,
  from: from_to.PlayerHandFromTo,
) -> Result(GameState, InvalidTransition) {
  let pid = from.id
  use p <- try(state |> state.get_player(pid) |> map_error(NoSuchPlayer))

  p
  |> player.remove_hand_card(card)
  |> map_error(just(CardNotInHand(card, p)))
  |> result.map(state.with_player(state, _))
}

fn to_hand(
  state: GameState,
  card: HandPileCard,
  pid: PlayerId,
) -> Result(GameState, InvalidTransition) {
  use player <- try(state |> state.get_player(pid) |> map_error(NoSuchPlayer))

  player.hand
  |> bag.insert(1, card)
  |> player.with_hand(player, _)
  |> state.with_player(state, _)
  |> Ok
}

fn from_stable(
  state: GameState,
  card: StableCard,
  from: from_to.PlayerStableFromTo,
) -> Result(GameState, InvalidTransition) {
  let pid = from.id
  use player <- try(state |> state.get_player(pid) |> map_error(NoSuchPlayer))

  player
  |> player.remove_stable_card(card)
  |> map_error(just(CardNotInStable(card, player)))
  |> result.map(state.with_player(state, _))
}

fn to_stable(
  state: GameState,
  card: StableCard,
  pid: PlayerId,
) -> Result(GameState, InvalidTransition) {
  use player <- try(state |> state.get_player(pid) |> map_error(NoSuchPlayer))

  player.stable
  |> bag.insert(1, card)
  |> player.with_stable(player, _)
  |> state.with_player(state, _)
  |> Ok
}

pub fn apply_transition(
  state: GameState,
  t: StateTransition,
) -> Result(GameState, InvalidTransition) {
  state
  |> apply_from(t)
  |> result.try(apply_to(_, t))
}

pub fn invert_transition(t: StateTransition) -> StateTransition {
  case t {
    StateTransBaby(inner) -> baby.invert(inner) |> StateTransBaby
    StateTransSpell(inner) -> spell.invert(inner) |> StateTransSpell
    StateTransUnicorn(inner) -> unicorn.invert(inner) |> StateTransUnicorn
    StateTransUpDown(inner) -> updown.invert(inner) |> StateTransUpDown
  }
}

import card.{
  type BabyCard, type SpellCard, type UnicornCard, type UpDownCard, BabyCard,
  StabledBaby, StabledUnicorn, StabledUpDown,
}
import card_test
import engine/engine.{
  type StateTransition, StateTransBaby, StateTransSpell, StateTransUnicorn,
  StateTransUpDown,
}
import engine/transitions/baby.{type BabySpot, type BabyTransition}
import engine/transitions/from_to.{PlayerHandFromTo, PlayerStableFromTo}
import engine/transitions/spell.{
  type SpellSpot, type SpellTransition, SpellTransition,
}
import engine/transitions/unicorn.{
  type UnicornSpot, type UnicornTransition, UnicornTransition,
}
import engine/transitions/updown.{
  type UpDownSpot, type UpDownTransition, UpDownTransition,
}
import gleam/dict
import gleam/list
import gleam/pair
import gleam/result
import gleeunit/should
import player
import qcheck.{type Generator, bind, from_generators, given, map, map2, return}
import qcheck_gleeunit_utils/test_spec
import state.{type GameState}
import state_test
import test_util.{
  pick_from_list_uniform, pick_from_list_uniform_index, pick_key_uniform,
}
import tote/bag
import util

fn other_player_gen(
  state: state.GameState,
  pid: player.PlayerId,
) -> Result(Generator(player.PlayerId), Nil) {
  case state.players |> dict.size {
    0 | 1 -> Error(Nil)
    _ ->
      state.players
      |> dict.drop([pid])
      |> pick_key_uniform
      |> result.lazy_unwrap(fn() { panic })
      |> Ok
  }
}

fn complete_baby_transition(
  state: GameState,
  from: BabySpot,
  card: BabyCard,
) -> Generator(BabyTransition) {
  {
    use to_stable_gen <- result.map(case from {
      baby.Stable(from_to.PlayerStableFromTo(pid), status) -> {
        use player <- result.map(other_player_gen(state, pid))

        player
        |> map(from_to.PlayerStableFromTo)
        |> map(baby.Stable(_, status))
      }
      baby.Nursery -> {
        use player <- result.map(pick_key_uniform(state.players))

        player
        |> map(from_to.PlayerStableFromTo)
        |> map2(card_test.stable_status_gen(), baby.Stable)
      }
    })

    from_generators(return(baby.Nursery), [
      to_stable_gen,
    ])
  }
  |> result.unwrap(return(baby.Nursery))
  |> map(baby.BabyTransition(from, card, _))
}

fn to_pile_gen(state: GameState) {
  from_generators(
    state.discard_pile
      |> list.length
      |> qcheck.bounded_int(0, _)
      |> map(from_to.Discard),
    [
      state.draw_pile
      |> list.length
      |> qcheck.bounded_int(0, _)
      |> map(from_to.Draw),
    ],
  )
}

fn fromto_player_gen(state: GameState) {
  state.players |> pick_key_uniform
}

fn complete_unicorn_transition(
  state: GameState,
  from: UnicornSpot,
  card: UnicornCard,
) -> Generator(UnicornTransition) {
  let status_gen = case from {
    unicorn.Stable(_, status) -> return(status)
    _ -> card_test.stable_status_gen()
  }

  case fromto_player_gen(state) {
    Ok(g) ->
      from_generators(to_pile_gen(state) |> map(unicorn.Pile), [
        g
          |> map(PlayerHandFromTo)
          |> map(unicorn.Hand),
        g
          |> map(PlayerStableFromTo)
          |> map2(status_gen, unicorn.Stable),
      ])
    Error(_) -> to_pile_gen(state) |> map(unicorn.Pile)
  }
  |> map(UnicornTransition(from, card, _))
}

fn complete_spell_transition(
  state: GameState,
  from: SpellSpot,
  card: SpellCard,
) -> Generator(SpellTransition) {
  case fromto_player_gen(state) {
    Ok(g) ->
      from_generators(to_pile_gen(state) |> map(spell.Pile), [
        g
        |> map(PlayerHandFromTo)
        |> map(spell.Hand),
      ])
    Error(_) -> to_pile_gen(state) |> map(spell.Pile)
  }
  |> map(SpellTransition(from, card, _))
}

fn from_pile_gen(
  pile: state.Pile,
) -> Result(Generator(#(from_to.PileFromTo, card.HandPileCard)), Nil) {
  case pile {
    state.Draw(p) -> {
      use pick <- result.try(p |> pick_from_list_uniform_index)
      pick |> map(pair.map_first(_, from_to.Draw)) |> Ok
    }
    state.Discard(p) -> {
      use pick <- result.try(
        p
        |> pick_from_list_uniform_index,
      )
      pick
      |> map(pair.map_first(_, from_to.Discard))
      |> Ok
    }
  }
}

fn from_player_hand_gen(
  state: GameState,
) -> Result(Generator(#(from_to.PlayerHandFromTo, card.HandPileCard)), Nil) {
  use g <- result.map(
    state.players
    // By filtering out empty hands, we can guarantee that if this pick succeeds, the downstream pick will aswell
    |> dict.filter(fn(_, p) { p |> player.get_hand |> bag.size > 0 })
    |> dict.values
    |> pick_from_list_uniform,
  )

  use p: player.Player <- bind(g)
  p.hand
  |> bag.to_map
  |> pick_key_uniform
  |> result.lazy_unwrap(fn() { panic })
  |> map(pair.new(PlayerHandFromTo(p.uuid), _))
}

fn from_player_stable_gen(state: GameState) {
  use g <- result.map(
    state.players
    // By filtering out empty stables, we can guarantee that if this pick succeeds, the downstream pick will aswell
    |> dict.filter(fn(_, p) { p |> player.get_stable |> bag.size > 0 })
    |> dict.values
    |> pick_from_list_uniform,
  )

  use p <- bind(g)
  p.stable
  |> bag.to_map
  |> pick_key_uniform
  |> result.lazy_unwrap(fn() { panic })
  |> map(pair.new(PlayerStableFromTo(p.uuid), _))
}

fn complete_updown_transition(
  state: GameState,
  from: UpDownSpot,
  card: UpDownCard,
) -> Generator(UpDownTransition) {
  let player_gens = case fromto_player_gen(state) {
    Ok(p) -> [
      p
        |> map(PlayerHandFromTo)
        |> map(updown.Hand),
      p
        |> map(PlayerStableFromTo)
        |> map(updown.Stable),
    ]
    Error(_) -> []
  }

  from_generators(to_pile_gen(state) |> map(updown.Pile), player_gens)
  |> map(UpDownTransition(from, card, _))
}

pub fn valid_from_pile_transition_gen(state: GameState) {
  let valid_gens =
    from_pile_gen(state.Draw(state.draw_pile))
    |> result.map(list.prepend([], _))
    |> result.unwrap([])
    |> list.append(
      from_pile_gen(state.Discard(state.draw_pile))
      |> result.map(list.prepend([], _))
      |> result.unwrap([]),
    )

  use g <- result.map(case valid_gens {
    [head, ..tail] -> Ok(from_generators(head, tail))
    _ -> Error(Nil)
  })

  use #(from, card) <- bind(g)

  case card {
    card.Spell(spell) ->
      complete_spell_transition(state, spell.Pile(from), spell)
      |> map(StateTransSpell)
    card.Unicorn(unicorn) ->
      complete_unicorn_transition(state, unicorn.Pile(from), unicorn)
      |> map(StateTransUnicorn)
    card.UpDown(updown) ->
      complete_updown_transition(state, updown.Pile(from), updown)
      |> map(StateTransUpDown)
  }
}

pub fn valid_from_hand_transition_gen(state: GameState) {
  use g <- result.map(from_player_hand_gen(state))

  use #(from, card) <- bind(g)
  case card {
    card.Spell(spell) ->
      complete_spell_transition(state, spell.Hand(from), spell)
      |> map(StateTransSpell)
    card.Unicorn(unicorn) ->
      complete_unicorn_transition(state, unicorn.Hand(from), unicorn)
      |> map(StateTransUnicorn)
    card.UpDown(updown) ->
      complete_updown_transition(state, updown.Hand(from), updown)
      |> map(StateTransUpDown)
  }
}

pub fn valid_from_stable_transition_gen(state: GameState) {
  use g <- result.map(from_player_stable_gen(state))
  use #(from, card) <- bind(g)
  case card {
    StabledUnicorn(unicorn, status) ->
      complete_unicorn_transition(state, unicorn.Stable(from, status), unicorn)
      |> map(StateTransUnicorn)
    StabledUpDown(updown) ->
      complete_updown_transition(state, updown.Stable(from), updown)
      |> map(StateTransUpDown)
    StabledBaby(baby, status:) ->
      complete_baby_transition(state, baby.Stable(from, status), baby)
      |> map(StateTransBaby)
  }
}

pub fn valid_from_nursery_transition_gen(
  state: GameState,
) -> Result(Generator(StateTransition), Nil) {
  use first <- result.map(
    state.nursery
    |> list.first,
  )

  complete_baby_transition(state, baby.Nursery, BabyCard(first))
  |> map(StateTransBaby)
}

pub type MaybeGenerator(a) =
  Result(Generator(a), Nil)

pub fn from_maybe_generators(l: List(MaybeGenerator(a))) -> MaybeGenerator(a) {
  use #(head, tail) <- result.map(l |> result.values |> util.list_pop_head)

  from_generators(head, tail)
}

pub fn valid_state_transition_gen(state: state.GameState) {
  [
    valid_from_hand_transition_gen(state),
    valid_from_nursery_transition_gen(state),
    valid_from_pile_transition_gen(state),
    valid_from_stable_transition_gen(state),
  ]
  |> from_maybe_generators
}

pub fn with_atleast_one_card_transition_always_possible() {
  use <- test_spec.make

  use state <- given(state_test.state_gen())

  state.nursery
  |> list.prepend(42)
  |> state.with_nursery(state, _)
  |> valid_state_transition_gen
  |> result.replace(Nil)
  |> should.be_ok
}

pub fn inverse_transition_test() {
  use <- test_spec.make

  use state <- given(state_test.state_gen())

  use t <- given(valid_state_transition_gen(state) |> should.be_ok)
  let inv_t = t |> engine.invert_transition

  state
  |> engine.apply_transition(t)
  |> should.be_ok
  |> engine.apply_transition(inv_t)
  |> should.be_ok
  |> should.equal(state)
}

pub type TransitionTestError {
  NoValid
  Invalid(engine.InvalidTransition)
}

pub type TransitionSequence =
  Result(#(GameState, List(StateTransition)), TransitionTestError)

fn state_machine_gen_next(
  acc: Generator(TransitionSequence),
) -> Generator(TransitionSequence) {
  {
    use maybe_acc <- bind(acc)
    {
      use #(cur_state, ts): #(GameState, List(StateTransition)) <- result.try(
        maybe_acc,
      )

      use t_gen: Generator(StateTransition) <- result.map(
        valid_state_transition_gen(cur_state)
        |> result.replace_error(NoValid),
      )

      use t: StateTransition <- bind(t_gen)

      cur_state
      |> engine.apply_transition(t)
      |> result.map_error(Invalid)
      |> result.map(pair.new(_, ts |> list.prepend(t)))
      |> return
    }
    |> test_util.lift_gen_maybe
  }
}

pub fn transition_sequence_gen(
  state: GameState,
  n: Int,
) -> Generator(TransitionSequence) {
  // Advance the state machine by n steps, noting the transitions taken
  list.range(0, n)
  |> list.fold(#(state, []) |> Ok |> return, fn(acc, _) {
    state_machine_gen_next(acc)
  })
}

pub fn multiple_transitions_and_inverts_test() {
  use <- test_spec.make

  use n <- given(qcheck.small_non_negative_int())
  use state <- given(state_test.state_gen())

  use r <- given(transition_sequence_gen(state, n))
  let #(end_state, ts) = r |> should.be_ok

  assert end_state != state

  ts
  |> list.try_fold(end_state, engine.apply_transition)
  |> should.be_ok
  |> should.equal(state)
}

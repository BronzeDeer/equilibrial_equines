import card.{type HandPileCard, type StableCard}
import choice.{type Choice, type Selection}
import effect.{type Effect}
import engine/effects/types.{type ChoiceCallback, type EffectContext}
import engine/engine.{type StateTransition}
import engine/transitions/baby
import engine/transitions/from_to
import filter
import filter_types
import gleam/dict
import gleam/list
import gleam/result.{map_error}
import player.{type PlayerId}
import state.{type GameState}
import tote/bag
import util

fn resolve_baby_summon(ctx: EffectContext) {
  {
    use next <- result.map(ctx.state.nursery |> list.first)
    next
    |> card.BabyCard
    |> baby.BabyTransition(
      baby.Nursery,
      _,
      baby.Stable(ctx.resolver_pid |> from_to.PlayerStableFromTo, card.Normal),
    )
    |> engine.StateTransBaby
    |> list.prepend([], _)
    |> Forced
  }
}

fn resolve_destroy(
  ctx: EffectContext,
  num: Int,
  filter: filter_types.CardFilter,
) {
  {
    ctx.state.players
    |> dict.filter(fn(pid, _) { pid != ctx.resolver_pid })
    |> dict.map_values(fn(_, p) { player.get_stable(p) })
    |> dict.map_values(fn(_, stable) {
      filter.filter_stable(stable, filter_types.Leaf(filter))
    })
    |> choice.CardsFromStableSelection(num, _, False)
    |> Ok
  }
}

// fn validate_and_force(sel: Selection) -> Result(Resolution, ResolutionError) {
//   case sel |> choice.is_possible {
//     True -> sel |> choice.to_forced_choice |> result.map(Forced) |> result.try_recover(sel)
//     False -> Error(ImpossibleAction)
//   }
// }

fn is_playable_card(card: HandPileCard) {
  case card {
    card.Spell(card.InstantCard(_, _)) -> False
    _ -> True
  }
}
// pub fn resolve(
//   ctx: EffectContext,
//   eff: Effect,
// ) -> Result(Resolution, ResolutionError) {
//   case eff {
//     effect.SummonBaby -> resolve_baby_summon(ctx)

//     effect.Destroy(num:, filter:) -> resolve_destroy(ctx, num, filter)
//     effect.Discard(num:) -> {
//       use player <- result.try(
//         ctx.state
//         |> state.get_player(ctx.resolver_pid)
//         |> map_error(NoSuchPlayer),
//       )
//       player
//       |> player.get_hand
//       |> choice.HandPileSelection(num, _)
//       |> Resolution
//       |> Ok
//     }
//     effect.Sacrifice(num:, filter:) -> {
//       let pid = ctx.resolver_pid
//       use player <- result.try(
//         ctx.state
//         |> state.get_player(pid)
//         |> map_error(NoSuchPlayer),
//       )

//       player
//       |> player.get_stable
//       |> choice.CardsFromStableSelection(
//         num,
//         [pair.new(pid, _)] |> dict.from_list,
//         True,
//       )
//       |> Ok
//     }
//     effect.PlayFromHand(filter:) -> {
//       use player <- result.try(
//         ctx.state
//         |> state.get_player(pid)
//         |> map_error(NoSuchPlayer),
//       )

//       player |> player.get_hand |> bag.filter
//     }
//   }
// }

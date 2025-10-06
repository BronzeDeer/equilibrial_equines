import card.{type HandPileCard, type StableCard}
import choice.{type Choice, type Selection}
import engine/engine.{type StateTransition}
import player.{type PlayerId}
import state.{type GameState}

pub type EffectOwner {
  InStable(StableCard)
  InHand(HandPileCard)
}

pub type EffectContext {
  EffectContext(
    resolver_pid: PlayerId,
    effect_owner: EffectOwner,
    state: GameState,
  )
}

pub type ChoiceCallback =
  fn(Choice) -> List(StateTransition)

pub type Resolution {
  Forced(List(StateTransition))
  Select(selection: Selection, cb: ChoiceCallback)
}

pub type ResolutionError {
  NoSuchPlayer(PlayerId)
  ImpossibleAction
}

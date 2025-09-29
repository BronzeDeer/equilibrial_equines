import filter_types

pub type Effect {
  Sacrifice(num: Int, filter: filter_types.CardFilter)
  Discard(num: Int)
  Destroy(num: Int, filter: filter_types.CardFilter)
  SummonBaby
  //PlayFromHand(filter: filter_types.CardFilter)
}

pub type EffectChain {
  May(EffectChain)
  Sequence(List(EffectChain))
  Then(EffectChain, EffectChain)
  Plain(Effect)
}

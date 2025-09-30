import card_filter_test.{card_filter_gen}
import effect.{
  type Effect, type EffectChain, Destroy, Discard, May, Plain, PlayFromHand,
  Sacrifice, Sequence, SummonBaby, Then,
}
import qcheck.{
  type Generator, from_generators, from_weighted_generators, map, map2, return,
}

pub fn sacrifice_effect_gen() {
  map2(qcheck.small_strictly_positive_int(), card_filter_gen(), Sacrifice)
}

pub fn destroy_effect_gen() {
  map2(qcheck.small_strictly_positive_int(), card_filter_gen(), Destroy)
}

pub fn discard_effect_gen() {
  map(qcheck.small_strictly_positive_int(), Discard)
}

pub fn play_effect_gen() {
  map(card_filter_gen(), PlayFromHand)
}

pub fn effect_chain_gen() -> Generator(EffectChain) {
  from_weighted_generators(#(900, map(effect_gen(), Plain)), [
    #(90, map(effect_chain_gen(), May)),
    #(9, map2(effect_chain_gen(), effect_chain_gen(), Then)),
    #(
      1,
      map(
        qcheck.generic_list(
          effect_chain_gen(),
          qcheck.small_strictly_positive_int(),
        ),
        Sequence,
      ),
    ),
  ])
}

pub fn effect_gen() -> Generator(Effect) {
  from_generators(discard_effect_gen(), [
    return(SummonBaby),
    sacrifice_effect_gen(),
    destroy_effect_gen(),
  ])
}

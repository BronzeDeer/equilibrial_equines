import card_filter_test.{card_filter_gen}
import effect.{
  type Effect, type EffectChain, Destroy, Discard, May, Plain, PlayFromHand,
  Sacrifice, Sequence, SummonBaby, Then,
}
import qcheck.{type Generator, from_generators, list_from, map, map2, return}
import util

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
  util.gen_recursive(map(effect_gen(), Plain), fn(g) {
    from_generators(map(g, May), [map2(g, g, Then), map(list_from(g), Sequence)])
  })
}

pub fn effect_gen() -> Generator(Effect) {
  from_generators(discard_effect_gen(), [
    return(SummonBaby),
    sacrifice_effect_gen(),
    destroy_effect_gen(),
  ])
}

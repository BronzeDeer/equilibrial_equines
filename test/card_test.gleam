import card.{
  type BabyCard, type CardMeta, type UnicornCard, BabyCard, CardMeta,
  MagicUnicorn, StabledBaby, StandardUnicorn, UltimateUnicorn, UnicornCard,
}
import effect_test.{effect_chain_gen}
import qcheck.{type Generator, from_generators, map, map2, tuple2}

pub fn card_meta_gen() -> Generator(CardMeta) {
  qcheck.string()
  |> map(CardMeta)
}

pub fn baby_card_gen() -> Generator(BabyCard) {
  qcheck.small_strictly_positive_int()
  |> map(BabyCard)
}

pub fn standard_unicorn_gen() -> Generator(UnicornCard) {
  use meta <- map(card_meta_gen())

  UnicornCard(meta, StandardUnicorn)
}

pub fn magic_unicorn_gen() {
  use #(meta, chain) <- map(tuple2(card_meta_gen(), effect_chain_gen()))

  UnicornCard(meta, MagicUnicorn(chain))
}

pub fn ultimate_unicorn_gen() {
  use #(meta, chain) <- map(tuple2(card_meta_gen(), effect_chain_gen()))

  UnicornCard(meta, UltimateUnicorn(chain))
}

pub fn unicorn_card_gen() -> qcheck.Generator(card.UnicornCard) {
  from_generators(standard_unicorn_gen(), [
    magic_unicorn_gen(),
    ultimate_unicorn_gen(),
  ])
}

pub fn magic_card_gen() {
  use #(meta, chain) <- map(tuple2(card_meta_gen(), effect_chain_gen()))

  card.MagicCard(meta, chain)
}

pub fn spell_card_gen() {
  from_generators(magic_card_gen(), [
    //instant_card_gen()
  ])
}

pub fn upgrade_card_gen() {
  use #(meta, chain) <- map(tuple2(card_meta_gen(), effect_chain_gen()))

  card.UpgradeCard(meta, chain)
}

pub fn downgrade_card_gen() {
  use #(meta, chain) <- map(tuple2(card_meta_gen(), effect_chain_gen()))

  card.DowngradeCard(meta, chain)
}

pub fn up_down_card_gen() {
  from_generators(upgrade_card_gen(), [
    downgrade_card_gen(),
  ])
}

pub fn hand_pile_card_gen() {
  from_generators(map(unicorn_card_gen(), card.UC), [
    map(up_down_card_gen(), card.UD),
    map(spell_card_gen(), card.SC),
  ])
}

pub fn stable_status_gen() {
  qcheck.return(card.Normal)
}

pub fn stabled_baby_gen() {
  map2(baby_card_gen(), stable_status_gen(), StabledBaby)
}

pub fn stabled_unicorn_gen() {
  map2(unicorn_card_gen(), stable_status_gen(), card.StabledUnicorn)
}

pub fn stabled_updown_gen() {
  up_down_card_gen() |> map(card.StabledUpDown)
}

pub fn stable_card_gen() {
  from_generators(stabled_baby_gen(), [
    stabled_unicorn_gen(),
    stabled_updown_gen(),
  ])
}

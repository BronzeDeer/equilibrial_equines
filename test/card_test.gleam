import card.{
  type CardMeta, type UnicornCard, BabyUnicorn, CardMeta, MagicUnicorn,
  StandardUnicorn, UltimateUnicorn, UnicornCard,
}
import effect_test.{effect_chain_gen}
import qcheck.{type Generator, from_generators, map, tuple2}

pub fn card_meta_gen() -> Generator(CardMeta) {
  qcheck.string()
  |> map(CardMeta)
}

pub fn baby_unicorn_gen() -> Generator(UnicornCard) {
  use #(meta, baby_id) <- map(tuple2(
    card_meta_gen(),
    qcheck.small_strictly_positive_int(),
  ))

  UnicornCard(meta, BabyUnicorn(baby_id))
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
    baby_unicorn_gen(),
    magic_unicorn_gen(),
    ultimate_unicorn_gen(),
  ])
}

pub fn magic_card_gen() {
  use #(meta, chain) <- map(tuple2(card_meta_gen(), effect_chain_gen()))

  card.MagicCard(meta, chain)
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

pub fn card_gen() {
  from_generators(map(unicorn_card_gen(), card.UC), [
    map(up_down_card_gen(), card.UD),
    map(magic_card_gen(), card.MC),
  ])
}

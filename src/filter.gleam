import card.{type HandPileCard, type UnicornCard, DowngradeCard, UpgradeCard}
import filter_types.{
  type CardFilter, type CardFilterChain, type UnicornFilter, AnyCard, AnyUnicorn,
  DowngradeCardFilter, MagicCardFilter, OnlyBabies, OnlyEffect, OnlyMagic,
  OnlyStandard, UpgradeCardFilter,
}
import player
import tote/bag.{type Bag}

fn apply_unicorn_filter(subject: UnicornCard, filter: UnicornFilter) -> Bool {
  case subject.body, filter {
    _, AnyUnicorn -> True
    card.StandardUnicorn, OnlyStandard -> True
    card.MagicUnicorn(_), OnlyMagic -> True
    card.MagicUnicorn(_), OnlyEffect -> True
    card.UltimateUnicorn(_), OnlyEffect -> True
    _, _ -> False
  }
}

type FilterSubject {
  HandPileSubject(card.HandPileCard)
  StableSubject(card.StableCard)
}

fn apply_handpile_filter(subject: HandPileCard, filter: CardFilter) -> Bool {
  case subject, filter {
    _, AnyCard -> True
    card.Unicorn(card), filter_types.UC(filter) ->
      apply_unicorn_filter(card, filter)
    _, filter_types.UC(_) -> False

    card.UpDown(DowngradeCard(_, _)), DowngradeCardFilter -> True
    _, DowngradeCardFilter -> False

    card.UpDown(UpgradeCard(_, _)), UpgradeCardFilter -> True
    _, UpgradeCardFilter -> False

    card.Spell(card.MagicCard(_, _)), MagicCardFilter -> True
    _, MagicCardFilter -> False
    //InstantFilter
  }
}

fn apply_baby_filter(_card: card.BabyCard, filter: CardFilter) {
  case filter {
    filter_types.UC(AnyUnicorn) -> True
    filter_types.UC(OnlyBabies) -> True
    _ -> False
  }
}

fn apply_stable_filter(subject: card.StableCard, filter: CardFilter) {
  case subject {
    card.StabledBaby(card, _) -> apply_baby_filter(card, filter)
    // For now we do not filter on Stable status, so we defer to the same logic as handpile filtering
    card.StabledUnicorn(card, _) ->
      apply_handpile_filter(card.Unicorn(card), filter)
    card.StabledUpDown(card) -> apply_handpile_filter(card.UpDown(card), filter)
  }
}

fn apply_card_filter_chain(
  subject: FilterSubject,
  chain: CardFilterChain,
) -> Bool {
  case subject, chain {
    HandPileSubject(card), filter_types.Leaf(filter) ->
      apply_handpile_filter(card, filter)
    StableSubject(card), filter_types.Leaf(filter) ->
      apply_stable_filter(card, filter)
    _, filter_types.And(a, b) ->
      apply_card_filter_chain(subject, a) && apply_card_filter_chain(subject, b)
    _, filter_types.Or(a, b) ->
      apply_card_filter_chain(subject, a) || apply_card_filter_chain(subject, b)
  }
}

pub fn filter_handpile(
  cards: Bag(HandPileCard),
  chain: CardFilterChain,
) -> Bag(HandPileCard) {
  bag.filter(cards, fn(card, _) {
    apply_card_filter_chain(HandPileSubject(card), chain)
  })
}

pub fn filter_stable(
  cards: player.Stable,
  chain: CardFilterChain,
) -> player.Stable {
  bag.filter(cards, fn(card, _) {
    apply_card_filter_chain(StableSubject(card), chain)
  })
}

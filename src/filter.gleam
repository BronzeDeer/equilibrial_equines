import card.{type Card, type UnicornCard, DowngradeCard, UpgradeCard}
import counting_set.{type CountingSet}
import filter_types.{
  type CardFilter, type CardFilterChain, type UnicornFilter, AnyCard, AnyUnicorn,
  DowngradeCardFilter, MagicCardFilter, OnlyBabies, OnlyEffect, OnlyMagic,
  OnlyStandard, UpgradeCardFilter,
}
import gleam/list
import stable

fn apply_unicorn_filter(subject: UnicornCard, filter: UnicornFilter) -> Bool {
  case subject.body, filter {
    _, AnyUnicorn -> True
    card.BabyUnicorn(_), OnlyBabies -> True
    card.StandardUnicorn, OnlyStandard -> True
    card.MagicUnicorn(_), OnlyMagic -> True
    card.MagicUnicorn(_), OnlyEffect -> True
    card.UltimateUnicorn(_), OnlyEffect -> True
    _, _ -> False
  }
}

fn apply_card_filter(subject: Card, filter: CardFilter) -> Bool {
  case subject, filter {
    _, AnyCard -> True
    card.UC(card), filter_types.UC(filter) -> apply_unicorn_filter(card, filter)
    _, filter_types.UC(_) -> False

    card.UD(DowngradeCard(_, _)), DowngradeCardFilter -> True
    _, DowngradeCardFilter -> False

    card.MC(_), MagicCardFilter -> True
    _, MagicCardFilter -> False

    card.UD(UpgradeCard(_, _)), UpgradeCardFilter -> True
    _, UpgradeCardFilter -> False
  }
}

fn apply_card_filter_chain(subject: Card, chain: CardFilterChain) -> Bool {
  case subject, chain {
    _, filter_types.Leaf(filter) -> apply_card_filter(subject, filter)
    _, filter_types.And(a, b) ->
      apply_card_filter_chain(subject, a) && apply_card_filter_chain(subject, b)
    _, filter_types.Or(a, b) ->
      apply_card_filter_chain(subject, a) || apply_card_filter_chain(subject, b)
  }
}

pub fn filter_cards(
  cards: CountingSet(Card),
  chain: CardFilterChain,
) -> CountingSet(Card) {
  counting_set.filter(cards, fn(card, _) {
    apply_card_filter_chain(card, chain)
  })
}

pub fn filter_cards_list(
  cards: List(Card),
  chain: CardFilterChain,
) -> List(Card) {
  list.filter(cards, apply_card_filter_chain(_, chain))
}

pub fn filter_stable(
  stable: stable.Stable,
  chain: CardFilterChain,
) -> CountingSet(Card) {
  filter_cards(stable.stable_cards_to_card_set(stable), chain)
}

pub fn filter_stable_list(
  stable: stable.Stable,
  chain: CardFilterChain,
) -> List(Card) {
  filter_cards_list(stable.to_card_list(stable), chain)
}

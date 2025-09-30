import filter_types.{
  AnyCard, AnyUnicorn, DowngradeCardFilter, MagicCardFilter, OnlyBabies,
  OnlyEffect, OnlyMagic, OnlyStandard, UpgradeCardFilter,
}

import gleam/list
import qcheck.{from_generators, from_weighted_generators, map, map2, return}

pub fn unicorn_filter_gen() {
  from_generators(
    return(AnyUnicorn),
    [OnlyBabies, OnlyEffect, OnlyMagic, OnlyStandard] |> list.map(return),
  )
}

pub fn card_filter_gen() {
  from_generators(
    unicorn_filter_gen() |> map(filter_types.UC),
    [MagicCardFilter, UpgradeCardFilter, DowngradeCardFilter, AnyCard]
      |> list.map(return),
  )
}

pub fn card_filter_chain_gen() {
  from_weighted_generators(#(90, map(card_filter_gen(), filter_types.Leaf)), [
    #(
      5,
      map2(card_filter_chain_gen(), card_filter_chain_gen(), filter_types.And),
    ),
    #(
      5,
      map2(card_filter_chain_gen(), card_filter_chain_gen(), filter_types.Or),
    ),
  ])
}

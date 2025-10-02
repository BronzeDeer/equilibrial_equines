import filter_types.{
  AnyCard, AnyUnicorn, DowngradeCardFilter, MagicCardFilter, OnlyBabies,
  OnlyEffect, OnlyMagic, OnlyStandard, UpgradeCardFilter,
}
import test_util.{gen_recursive}

import gleam/list
import qcheck.{from_generators, map, map2, return}

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
  gen_recursive(card_filter_gen() |> map(filter_types.Leaf), fn(g) {
    from_generators(map2(g, g, filter_types.And), [map2(g, g, filter_types.Or)])
  })
}

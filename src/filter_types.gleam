pub type CardFilterChain {
  Leaf(CardFilter)
  And(CardFilterChain, CardFilterChain)
  Or(CardFilterChain, CardFilterChain)
}

pub type CardFilter {
  UC(UnicornFilter)
  MagicCardFilter
  UpgradeCardFilter
  DowngradeCardFilter
  AnyCard
}

pub type UnicornFilter {
  OnlyBabies
  OnlyStandard
  // It's unclear whether Ultimate Unicorns count as magic or are exempt from certain masquerades
  OnlyMagic
  OnlyEffect
  AnyUnicorn
}

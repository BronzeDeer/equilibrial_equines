import effect.{type EffectChain}

pub type CardMeta {
  CardMeta(text: String)
}

pub type MagicBody {
  MagicBody(EffectChain)
}

pub type UnicornBody {
  StandardUnicorn
  BabyUnicorn(id: Int)
  MagicUnicorn(effect: EffectChain)
  UltimateUnicorn(effect: EffectChain)
}

pub type Card {
  UC(UnicornCard)
  MC(MagicCard)
  UD(UpDownCard)
}

pub type UnicornCard {
  UnicornCard(meta: CardMeta, body: UnicornBody)
  //InstantCard(meta: InstantBody)
}

pub type MagicCard {
  MagicCard(meta: CardMeta, body: EffectChain)
}

pub type UpDownCard {
  UpgradeCard(meta: CardMeta, body: EffectChain)
  DowngradeCard(meta: CardMeta, body: EffectChain)
}

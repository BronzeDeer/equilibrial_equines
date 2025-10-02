import effect.{type EffectChain}

pub type CardMeta {
  CardMeta(text: String)
}

pub type MagicBody {
  MagicBody(EffectChain)
}

pub type UnicornBody {
  StandardUnicorn
  MagicUnicorn(effect: EffectChain)
  UltimateUnicorn(effect: EffectChain)
}

pub type BabyCard {
  BabyCard(id: Int)
}

pub type HandPileCard {
  Unicorn(UnicornCard)
  Spell(SpellCard)
  UpDown(UpDownCard)
}

pub type UnicornStableStatus {
  Normal
  // Blinded
  // Masqueraded
}

pub type StableCard {
  StabledUnicorn(card: UnicornCard, status: UnicornStableStatus)
  StabledUpDown(card: UpDownCard)
  StabledBaby(card: BabyCard, status: UnicornStableStatus)
}

pub type UnicornCard {
  UnicornCard(meta: CardMeta, body: UnicornBody)
}

pub type SpellCard {
  MagicCard(meta: CardMeta, body: EffectChain)
  //InstantCard(meta: CardMeta, body: InstantBody)
}

pub type UpDownCard {
  UpgradeCard(meta: CardMeta, body: EffectChain)
  DowngradeCard(meta: CardMeta, body: EffectChain)
}

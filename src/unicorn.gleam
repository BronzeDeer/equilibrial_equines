import effect.{type EffectChain}

pub type Unicorn {
  BabyUnicorn
  StandardUnicorn
  MagicUnicorn(effect: EffectChain)
  UltimateUnicorn(effect: EffectChain)
}

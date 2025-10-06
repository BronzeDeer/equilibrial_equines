import card.{type HandPileCard}
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/set.{type Set}
import player.{type PlayerId, type Stable}
import tote/bag.{type Bag}

pub type Selection {
  HandPileSelection(num: Int, options: Bag(HandPileCard))
  CardsFromStableSelection(
    num: Int,
    options: Dict(PlayerId, Stable),
    from_same_stable: Bool,
  )
  PlayerSelection(num: Int, options: Set(PlayerId))
}

pub type Choice {
  HandPileCards(cards: Bag(HandPileCard))
  CardsFromStable(cards: Dict(PlayerId, Stable))
  Players(Set(PlayerId))
}

fn bag_total(bag: Bag(a)) -> Int {
  bag.fold(bag, 0, fn(acc, _, count) { int.add(count, acc) })
}

fn bag_subset(sub: Bag(a), super: Bag(a)) -> Bool {
  // A intersect B == A <=> A subset B
  bag.intersect(sub, super) == sub
}

fn dict_matched_entries(
  pair_from: Dict(key, member),
  with_from: Dict(key, member),
) -> Result(Dict(key, #(member, member)), Nil) {
  pair_from
  |> dict.fold(Ok(dict.new()), fn(acc, key, from_elem) {
    result.try(acc, fn(d) {
      with_from
      |> dict.get(key)
      |> result.map(pair.new(from_elem, _))
      |> result.map(dict.insert(d, key, _))
    })
  })
}

fn apply_pair(in: #(a, b), fun: fn(a, b) -> c) -> c {
  fun(pair.first(in), pair.second(in))
}

pub fn is_choice_valid(selection: Selection, choice: Choice) -> Bool {
  case selection, choice {
    HandPileSelection(num, options), HandPileCards(cards) -> {
      num == bag_total(cards) && bag_subset(cards, options)
    }
    CardsFromStableSelection(num, options, from_same_stable),
      CardsFromStable(choices)
    -> {
      let chosen_players =
        choices
        |> dict.filter(fn(_, stable) { !bag.is_empty(stable) })

      { !from_same_stable || dict.size(chosen_players) == 1 }
      && {
        chosen_players
        |> dict.keys
        |> set.from_list
        |> set.is_subset(options |> dict.keys |> set.from_list)
      }
      && {
        use zipped_stables <- result.try(
          chosen_players
          |> dict_matched_entries(options),
        )

        zipped_stables
        |> dict.fold(True, fn(acc, _, pair) {
          acc && apply_pair(pair, bag_subset)
        })
        |> Ok
      }
      |> result.lazy_unwrap(fn() { False })
      && {
        let total =
          chosen_players
          |> dict.values
          |> list.map(bag_total)
          |> list.fold(0, int.add)

        total == num
      }
    }
    PlayerSelection(num, options), Players(choices) -> {
      num == set.size(choices) && choices |> set.is_subset(options)
    }
    _, _ -> False
  }
}

pub fn is_possible(s: Selection) -> Bool {
  case s {
    CardsFromStableSelection(num:, options:, from_same_stable:) -> {
      let nums =
        options
        |> dict.values
        |> list.map(bag_total)

      case from_same_stable, nums |> list.max(int.compare) {
        _, Error(_) -> False
        True, Ok(max) -> num <= max
        False, _ -> num <= nums |> list.fold(0, int.add)
      }
    }
    HandPileSelection(num:, options:) -> num <= options |> bag_total
    PlayerSelection(num:, options:) -> num <= options |> set.size
  }
}

fn from_stable_to_forced(
  num: Int,
  options: Dict(PlayerId, Stable),
  from_same_stable: Bool,
) -> Result(Choice, Nil) {
  case from_same_stable {
    True -> {
      let eligble = options |> dict.filter(fn(_, l) { num <= l |> bag_total })
      case eligble |> dict.values |> list.map(bag.size) {
        // Single eligble player with exact amount of cards to chose
        [count] if count == num -> eligble |> CardsFromStable |> Ok
        _ -> Error(Nil)
      }
    }
    False -> {
      case
        options
        |> dict.values
        |> list.map(bag.size)
        |> list.fold(0, int.add)
      {
        count if count == num -> options |> CardsFromStable |> Ok
        _ -> Error(Nil)
      }
    }
  }
}

pub fn to_forced_choice(s: Selection) -> Result(Choice, Nil) {
  case s {
    CardsFromStableSelection(num:, options:, from_same_stable:) ->
      from_stable_to_forced(num, options, from_same_stable)
    HandPileSelection(num:, options:) ->
      case options |> bag.size {
        count if num == count -> options |> HandPileCards |> Ok
        _ -> Error(Nil)
      }

    PlayerSelection(num:, options:) ->
      case options |> set.size {
        count if num == count -> options |> Players |> Ok
        _ -> Error(Nil)
      }
  }
}

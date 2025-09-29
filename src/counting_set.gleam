import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import gleam/set.{type Set}

pub opaque type CountingSet(member) {
  CountingSet(inner: Dict(member, Int))
}

pub fn new() -> CountingSet(member) {
  CountingSet(dict.new())
}

pub fn contains(set: CountingSet(member), member: member) -> Bool {
  set.inner |> dict.has_key(member)
}

pub fn delete(set: CountingSet(member), value: member) -> CountingSet(member) {
  case set.inner |> dict.get(value) {
    Ok(n) -> set.inner |> dict.insert(value, n - 1)
    _ -> set.inner |> dict.delete(value)
  }
  |> CountingSet
}

pub fn delete_or_error(
  set: CountingSet(member),
  value: member,
) -> Result(CountingSet(member), Nil) {
  set |> get(value) |> result.map(fn(_) { delete(set, value) })
}

pub fn delete_all(
  set: CountingSet(member),
  value: member,
) -> CountingSet(member) {
  set.inner |> dict.delete(value) |> CountingSet
}

pub fn difference(
  set: CountingSet(member),
  minus: CountingSet(member),
) -> CountingSet(member) {
  set.inner
  |> dict.fold(dict.new(), fn(acc, mem, num_a) {
    case minus.inner |> dict.get(mem) {
      Ok(num_b) if num_b - num_a > 0 -> dict.insert(acc, mem, num_b - num_a)
      _ -> acc
    }
  })
  |> CountingSet
}

pub fn drop_all(
  set: CountingSet(member),
  values: List(member),
) -> CountingSet(member) {
  set.inner |> dict.drop(values) |> CountingSet
}

pub fn each(set: CountingSet(member), fun: fn(member, Int) -> a) -> Nil {
  set.inner |> dict.each(fun)
}

pub fn filter(
  set: CountingSet(member),
  fun: fn(member, Int) -> Bool,
) -> CountingSet(member) {
  set.inner |> dict.filter(fun) |> CountingSet
}

pub fn fold(
  set: CountingSet(member),
  initial: acc,
  with: fn(acc, member, Int) -> acc,
) -> acc {
  set.inner |> dict.fold(initial, with)
}

pub fn from_list(list: List(member)) -> CountingSet(member) {
  list |> list.fold(new(), insert)
}

pub fn from_counts(list: List(#(member, Int))) -> CountingSet(member) {
  dict.from_list(list) |> CountingSet
}

pub fn get(from: CountingSet(member), value: member) -> Result(Int, Nil) {
  from.inner |> dict.get(value)
}

pub fn insert(into: CountingSet(member), value: member) -> CountingSet(member) {
  into |> insert_num(value, 1)
}

pub fn insert_num(
  into: CountingSet(member),
  value: member,
  num: Int,
) -> CountingSet(member) {
  case into.inner |> dict.get(value) {
    Ok(i) -> dict.insert(into.inner, value, i + num)
    Error(_) -> dict.insert(into.inner, value, num)
  }
  |> CountingSet
}

// Tests for key disjointness 
pub fn is_disjoint(
  set_a: CountingSet(member),
  set_b: CountingSet(member),
) -> Bool {
  set_a |> fold(True, fn(acc, k, _) { acc && !{ set_b |> contains(k) } })
}

pub fn is_empty(set: CountingSet(member)) -> Bool {
  set.inner |> dict.is_empty
}

pub fn is_subset(sub: CountingSet(member), super: CountingSet(member)) -> Bool {
  sub
  |> fold(True, fn(acc, k, sub_n) {
    acc
    && case super |> get(k) {
      Ok(super_n) -> super_n >= sub_n
      _ -> False
    }
  })
}

pub fn keys(set: CountingSet(member)) -> List(member) {
  set.inner |> dict.keys
}

pub fn map_keys(
  set: CountingSet(member),
  fun: fn(member) -> member_new,
) -> CountingSet(member_new) {
  set
  |> fold(new(), fn(acc, k, v) { acc |> insert_num(fun(k), v) })
}

pub fn map_values(set: CountingSet(member), fun: fn(member, Int) -> Int) {
  set.inner |> dict.map_values(fun)
}

pub fn union(
  into: CountingSet(member),
  from: CountingSet(member),
) -> CountingSet(member) {
  from |> fold(into, insert_num)
}

pub fn size(set: CountingSet(member)) {
  set.inner |> dict.size
}

pub fn symmetric_difference(
  set_a: CountingSet(member),
  set_b: CountingSet(member),
) -> CountingSet(member) {
  let a_minus_b = set_a |> difference(set_b)
  let b_minus_a = set_b |> difference(set_a)

  union(a_minus_b, b_minus_a)
}

pub fn take(
  set: CountingSet(member),
  desired: List(member),
) -> CountingSet(member) {
  desired
  |> list.fold(new(), fn(acc, k) {
    case set |> get(k) {
      Ok(v) -> acc |> insert_num(k, v)
      _ -> acc
    }
  })
}

pub fn total_count(set: CountingSet(member)) -> Int {
  set |> fold(0, fn(total, _, n) { total + n })
}

pub fn to_dict(set: CountingSet(member)) -> Dict(member, Int) {
  set.inner
}

pub fn to_key_set(set: CountingSet(member)) -> Set(member) {
  set |> keys |> set.from_list
}

pub fn to_list(set: CountingSet(member)) -> List(member) {
  set
  |> fold(list.new(), fn(acc, k, v) { acc |> list.append(list.repeat(k, v)) })
}

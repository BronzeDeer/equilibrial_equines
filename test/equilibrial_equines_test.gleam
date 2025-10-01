import qcheck_gleeunit_utils/run

pub fn main() -> Nil {
  //gleeunit.main()
  // Run parallel tests via the gleeunit utils
  run.run_gleeunit()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  let name = "Joe"
  let greeting = "Hello, " <> name <> "!"

  assert greeting == "Hello, Joe!"
}
// pub fn construct_game_test() {
//   let baby = UnicornCard(card.CardMeta("test baby"), body: BabyUnicorn(42))
//   let standard =
//     UnicornCard(card.CardMeta("test standard"), body: card.StandardUnicorn)
//   let player_a =
//     Player(
//       "a",
//       new()
//         |> insert(card.UC(baby)),
//       stable: stable.Stable(
//         new()
//           |> insert(standard),
//         new(),
//       ),
//     )

//   let player_b =
//     Player(
//       "b",
//       new()
//         |> insert(card.UC(standard)),
//       stable: stable.Stable(
//         new()
//           |> insert(baby),
//         new(),
//       ),
//     )
// }

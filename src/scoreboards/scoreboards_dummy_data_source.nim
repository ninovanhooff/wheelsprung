import playdate/api
import std/tables

let dummyScoreboards* = {
  "hills" : PDScoresList(
    boardID: "hills",
    scores: @[
      PDScore(player: "John", value: 20_000_240, rank: 1),
      PDScore(player: "Jane", value: 20_000_000, rank: 2),
      PDScore(player: "Jack", value: 19_999_999, rank: 3),
      PDScore(player: "Jill", value: 19_999_998, rank: 4),
    ]
  ),
}.toTable
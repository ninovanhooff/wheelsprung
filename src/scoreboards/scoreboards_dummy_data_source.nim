import playdate/api
import std/tables

let dummyScoreboards* = {
  "hills" : PDScoresList(
    boardID: "hills",
    scores: @[
      PDScore(player: "John", value: 800_240, rank: 1),
      PDScore(player: "Jane", value: 700_000, rank: 2),
      PDScore(player: "Jack", value: 699_999, rank: 3),
      PDScore(player: "Jill", value: 599_998, rank: 4),
    ]
  ),
  "leaderboard" : PDScoresList(
    boardID: "leaderboard",
    scores: @[
      PDScore(player: "Jane", value: 20_000_440, rank: 1),
      PDScore(player: "John", value: 20_000_240, rank: 2),
      PDScore(player: "Jill", value: 19_999_998, rank: 3),
      PDScore(player: "Jack", value: 19_999_997, rank: 4),
    ]
  ),
}.toTable
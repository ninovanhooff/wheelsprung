import playdate/api
import std/tables

let dummyScoreboards* = {
  "tutorialaccelerate": PDScoresList(
    boardID: "tutorialaccelerate",
    scores: @[
      PDScore(player: "John", value: 1_000_000, rank: 1),
      PDScore(player: "Jane", value: 999_999, rank: 2),
      PDScore(player: "Jack", value: 999_998, rank: 3),
      PDScore(player: "Jill", value: 999_997, rank: 4),
      PDScore(player: "Jim", value: 999_996, rank: 5),
      PDScore(player: "Joe", value: 999_995, rank: 6),
      PDScore(player: "Jenny", value: 999_994, rank: 7),
      PDScore(player: "James", value: 999_993, rank: 8),
      PDScore(player: "Jasmine", value: 999_992, rank: 9),
      PDScore(player: "Jordan", value: 999_991, rank: 10),
      PDScore(player: "Jerry", value: 999_990, rank: 11)
    ]
  ),
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
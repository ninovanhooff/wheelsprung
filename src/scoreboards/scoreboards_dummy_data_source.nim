import playdate/api
import std/tables

let dummyScoreboards* = {
  "tutorialaccelerate": PDScoresList(
    boardID: "tutorialaccelerate",
    scores: @[
      PDScore(player: "John", value: 995_619, rank: 1),
      PDScore(player: "Jane", value: 995_601, rank: 2),
      PDScore(player: "Jack", value: 995_600, rank: 3),
      PDScore(player: "Jill", value: 994_997, rank: 4),
      PDScore(player: "Jim", value: 994_996, rank: 5),
      PDScore(player: "Joe", value: 994_995, rank: 6),
      PDScore(player: "Jenny", value: 994_994, rank: 7),
      PDScore(player: "James", value: 994_993, rank: 8),
      PDScore(player: "Jasmine", value: 994_992, rank: 9),
      PDScore(player: "Jordan", value: 994_991, rank: 10),
      PDScore(player: "Jerry", value: 994_990, rank: 11)
    ],
    lastUpdated: 783437075
  ),
  "hills" : PDScoresList(
    boardID: "hills",
    scores: @[
      PDScore(player: "John", value: 800_240, rank: 1),
      PDScore(player: "Jane", value: 700_000, rank: 2),
      PDScore(player: "Jack", value: 699_994, rank: 3),
      PDScore(player: "Jill", value: 599_998, rank: 4),
    ]
  ),
  "leaderboard" : PDScoresList(
    boardID: "leaderboard",
    scores: @[
      PDScore(player: "Jane", value: 990_000, rank: 1),
      PDScore(player: "John", value: 899_240, rank: 2),
      PDScore(player: "Jill", value: 898_998, rank: 3),
      PDScore(player: "Jack", value: 897_997, rank: 4),
    ]
  ),
}.toTable
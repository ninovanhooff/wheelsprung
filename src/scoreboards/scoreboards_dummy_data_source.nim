import playdate/api
import std/tables

let dummyScoreboards* = {
  "tutorialaccelerate": PDScoresList(
    boardID: "tutorialaccelerate",
    scores: @[
      PDScore(player: "JonathanSmithJunior1", value: 995_619, rank: 1),
      PDScore(player: "Jordan", value: 995_601, rank: 101),
      PDScore(player: "Jack", value: 995_600, rank: 1002),
      PDScore(player: "Jill", value: 994_997, rank: 2003),
      PDScore(player: "Jim", value: 994_996, rank: 3004),
      PDScore(player: "JonathanSmithJunior2", value: 994_995, rank: 4005),
      PDScore(player: "Jenny", value: 994_994, rank: 5006),
      PDScore(player: "James", value: 994_993, rank: 6007),
      PDScore(player: "Nino", value: 994_992, rank: 7008),
      PDScore(player: "Jasmine", value: 994_991, rank: 8009),
    ],
    lastUpdated: 783437075
  ),
  "tutorialturnaround": PDScoresList(
    boardID: "tutorialturnaround",
    scores: @[
      PDScore(player: "JonathanSmithSenior1", value: 995_619, rank: 1000),
      PDScore(player: "Bordan", value: 995_601, rank: 1001),
      PDScore(player: "Black", value: 995_600, rank: 1002),
      PDScore(player: "Gill", value: 994_997, rank: 1003),
      PDScore(player: "Jones", value: 994_996, rank: 1004),
      PDScore(player: "JonathanSmithJunior2", value: 994_995, rank: 1005),
      PDScore(player: "Jonny", value: 994_994, rank: 1006),
      PDScore(player: "James", value: 994_993, rank: 1007),
      PDScore(player: "Nino", value: 994_992, rank: 1008),
      PDScore(player: "Jasmine", value: 994_991, rank: 1009),
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
}.toOrderedTable
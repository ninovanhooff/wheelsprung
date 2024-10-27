{.push raises: [].}

import playdate/api
import common/utils
import std/options
import std/tables
import scoreboards_types

type
  ScoreboardsMemoryDataSource* = ref object of RootObj
    scoreboards: Table[BoardId, PDScoresList]

let scoreboardsCache* = ScoreboardsMemoryDataSource(
  scoreboards: initTable[BoardId, PDScoresList]()
)
  ## Global Singleton for the ScoreboardsMemoryDataSource
  ## 

proc getScoreboard*(cache: ScoreboardsMemoryDataSource, boardID: string): Option[PDScoresList] =
  try:
    return some(cache.scoreboards[boardID])
  except KeyError:
    return none(PDScoresList)

proc getScoreboards*(cache: ScoreboardsMemoryDataSource): Table[BoardId, PDScoresList] =
  cache.scoreboards

proc setScoreboards*(cache: ScoreboardsMemoryDataSource, scoreboards: Table[BoardId, PDScoresList]) =
  cache.scoreboards = scoreboards

proc createScoreboards*(cache: ScoreboardsMemoryDataSource, boardIds: seq[string]) =
  for boardID in boardIds:
    cache.scoreboards[boardID] = PDScoresList(boardID: boardID)

proc setScoreboard*(cache: ScoreboardsMemoryDataSource, scoreboard: PDScoresList) =
  cache.scoreboards[scoreboard.boardID] = scoreboard

proc addScore*(cache: ScoreboardsMemoryDataSource, boardID: string, score: PDScore) =
  let board = cache.getScoreboard(boardID)
  if board.isSome:
    var updatedBoard = board.get
    var newScores = updatedBoard.scores
    newScores.add(score)
    updatedBoard.scores = newScores
    cache.scoreboards[boardID] = updatedBoard
  else:
    print "ERROR: score not saved. Scoreboards memory cache not initialised. Could not find board with ID: ", boardID



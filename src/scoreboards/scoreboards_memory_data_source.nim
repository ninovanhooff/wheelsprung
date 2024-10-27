import playdate/api
import common/utils
import std/options
import std/tables
import scoreboards_types

type
  ScoreboardsMemoryDataSource* = ref object of RootObj
    scoreboards: Table[BoardId, PDScoresList]

let scoreboardsMemoryDataSource = ScoreboardsMemoryDataSource(
  scoreboards: initTable[BoardId, PDScoresList]()
)
  ## Global Singleton for the ScoreboardsMemoryDataSource
  ## 

proc getScoreboard*(cache: ScoreboardsMemoryDataSource, boardID: string): Option[PDScoresList] =
  if cache.scoreboards.hasKey(boardID):
    return some(cache.scoreboards[boardID])
  else:
    return none(PDScoresList)

proc getScoreboards*(cache: ScoreboardsMemoryDataSource): Table[BoardId, PDScoresList] =
  cache.scoreboards

proc addScoreboard*(cache: ScoreboardsMemoryDataSource, scoreboard: PDScoresList) =
  cache.scoreboards[scoreboard.boardID] = scoreboard

proc addScore*(cache: ScoreboardsMemoryDataSource, boardID: string, score: PDScore) =
  let board = cache.getScoreboard(boardID)
  if board.isSome:
    board.get.scores.add(score)
  else:
    print "ERROR: score not saved. Scoreboards memory cache not initialised. Could not find board with ID: ", boardID



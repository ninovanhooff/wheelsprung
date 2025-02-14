{.push raises: [].}

import playdate/api
import common/utils
import std/options
import std/tables
import scoreboards_types

type
  ScoreboardsMemoryDataSource* = ref object of RootObj
    scoreboards: OrderedTable[BoardId, PDScoresList]

let scoreboardsCache* = ScoreboardsMemoryDataSource(
  scoreboards: initOrderedTable[BoardId, PDScoresList]()
)
  ## Global Singleton for the ScoreboardsMemoryDataSource
  ## 

proc getScoreboard*(cache: ScoreboardsMemoryDataSource, boardID: string): Option[PDScoresList] =
  try:
    return some(cache.scoreboards[boardID])
  except KeyError:
    return none(PDScoresList)

proc getScoreboards*(cache: ScoreboardsMemoryDataSource): OrderedTable[BoardId, PDScoresList] =
  cache.scoreboards

proc setScoreboards*(cache: ScoreboardsMemoryDataSource, scoreboards: OrderedTable[BoardId, PDScoresList]) =
  cache.scoreboards = scoreboards

proc createScoreboards*(cache: ScoreboardsMemoryDataSource, boardIds: seq[string]) =
  for boardID in boardIds:
    cache.scoreboards[boardID] = PDScoresList(boardID: boardID)

proc setScoreboard*(cache: ScoreboardsMemoryDataSource, scoreboard: PDScoresList) =
  cache.scoreboards[scoreboard.boardID] = scoreboard



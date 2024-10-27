import std/seqUtils
import std/tables
import std/sugar
import playdate/api
import scoreboards_types
import level_meta/level_data
import scoreboards_dummy_data_source

var
  validBoardIds: seq[string] = @[]

proc getScoreboards*(): seq[PDScoresList] =
  dummyScoreboards.values.toSeq

proc initScoreboardsService() =
  # validBoardIds = dummyScoreboards.keys.toSeq
  validBoardIds = collect(newSeq):
    for levelMeta in officialLevels.values:
      if levelMeta.scoreboardId != "":
        levelMeta.scoreboardId

initScoreboardsService()
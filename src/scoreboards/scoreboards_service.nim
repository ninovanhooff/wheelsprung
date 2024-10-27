{.push raises: [].}

import std/seqUtils
import std/tables
import std/options
import std/sugar
import playdate/api
import scoreboards_types
import level_meta/level_data
import scoreboards_dummy_data_source
import scoreboards_memory_data_source
import common/shared_types
import common/utils

var
  validBoardIds: seq[string] = @[]
  boardsLoadingCounts = initTable[string, uint32]()
  optCurrentPlayerName = none(string)

proc increaseLoadingCount*(boardId: BoardId) =
  boardsLoadingCounts[boardId] = boardsLoadingCounts.getOrDefault(boardId, 0) + 1

proc decreaseLoadingCount*(boardId: BoardId) =
  boardsLoadingCounts[boardId] = boardsLoadingCounts.getOrDefault(boardId, 0) - 1

proc getScoreboards*(): seq[PDScoresList] =
  if scoreboardsCache.getScoreboards.len == 0:
    scoreboardsCache.setScoreboards(dummyScoreboards)
    # scoreboardsCache.createScoreboards(validBoardIds)
  return scoreboardsCache.getScoreboards.values.toSeq

proc getScoreBoard*(boardId: BoardId): Option[PDScoresList] =
  return scoreboardsCache.getScoreboard(boardId)

proc refreshBoard(boardId: BoardId) =
  let resultCode = playdate.scoreboards.getScores(boardId) do (scoresList: PDResult[PDScoresList]) -> void:
    boardId.decreaseLoadingCount()
    case scoresList.kind
    of PDResultSuccess: 
      print "===== NETWORK Scores OK", $scoresList.result
      scoreboardsCache.setScoreboard(scoresList.result)
    of PDResultError: 
      print "===== NETWORK Scores ERROR", scoresList.message

  boardId.increaseLoadingCount()
  print "===== NETWORK Scores START", boardId, $resultCode

proc calculateScore(gameResult: GameResult): uint32 =
  let timeScore = 1_000_000 - gameResult.time
  let starScore = if gameResult.starCollected: 1 else: 0
  let score = timeScore + starScore
  return score.uint32

proc shouldSubmitScore(boardId: BoardId, score: uint32): bool =
  let board = getScoreBoard(boardId)
  if board.isNone:
    return true
  if optCurrentPlayerName.isNone:
    # we don't know the current player name, so we can't compare new score to old scores
    return true
  let playerName = optCurrentPlayerName.get
  let scores = board.get.scores
  let optOldPlayerScore = scores.findFirst(it => it.player == playerName)
  if optOldPlayerScore.isNone:
    # player has no score yet
    return true
  return score > optOldPlayerScore.get.value


proc submitScore*(gameResult: GameResult) =
  let boardId = getLevelMeta(gameResult.levelId).scoreboardId
  if not validBoardIds.contains(boardId):
    print "Not submitting gameresult to Scoreboards.'", boardId, "'is not a valid board id"
    return

  let score = gameResult.calculateScore()
  if not shouldSubmitScore(boardId, score):
    print "Not submitting gameresult to Scoreboards. Score is not in top 10 or not higher than current score"
    return

  let resultCode = playdate.scoreboards.addScore(boardId, score) do (score: PDResult[PDScore]) -> void:
    boardId.decreaseLoadingCount()
    case score.kind
    of PDResultSuccess:
      print "===== NETWORK addScore OK", score.result.repr
      optCurrentPlayerName = some(score.result.player)
      refreshBoard(boardId)
    of PDResultError: 
      print "==== NETWORK addScore ERROR: ", score.message

  boardId.increaseLoadingCount()
  print "===== NETWORK addScore START", boardId, score, resultCode

proc initScoreboardsService() =
  # validBoardIds = dummyScoreboards.keys.toSeq
  validBoardIds = collect(newSeq):
    for levelMeta in officialLevels.values:
      if levelMeta.scoreboardId != "":
        levelMeta.scoreboardId

initScoreboardsService()
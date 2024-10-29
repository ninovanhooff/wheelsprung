{.push raises: [].}

import std/seqUtils
import std/tables
import std/options
import std/sugar
import playdate/api
import scoreboards_types
export scoreboards_types
import level_meta/level_data
import scoreboards_dummy_data_source
import scoreboards_memory_data_source
import common/utils

var
  validBoardIds: seq[string] = @[]
  boardsLoadingCounts = initTable[string, uint32]()
  optCurrentPlayerName = none(string)
  fetchAllInProgress = false
  scoreboardChangedCallbacks: Table[string, ScoreboardChangedCallback] = initTable[string, ScoreboardChangedCallback]()

proc increaseLoadingCount(boardId: BoardId) =
  boardsLoadingCounts[boardId] = boardsLoadingCounts.getOrDefault(boardId, 0) + 1

proc decreaseLoadingCount(boardId: BoardId) =
  boardsLoadingCounts[boardId] = boardsLoadingCounts.getOrDefault(boardId, 0) - 1

proc getScoreboards*(): seq[PDScoresList] =
  if scoreboardsCache.getScoreboards.len == 0:
    # scoreboardsCache.setScoreboards(dummyScoreboards)
    scoreboardsCache.createScoreboards(validBoardIds)
  return scoreboardsCache.getScoreboards.values.toSeq

proc getScoreBoard*(boardId: BoardId): Option[PDScoresList] =
  return scoreboardsCache.getScoreboard(boardId)

proc getGlobalBest*(boardId: BoardId): Option[uint32] =
  let board = getScoreBoard(boardId)
  if board.isNone:
    return none(uint32)
  let scores = board.get.scores
  if scores.len == 0:
    return none(uint32)
  return some(scores[0].value)

proc addScoreboardChangedCallback*(key: string, callback: ScoreboardChangedCallback) =
  scoreboardChangedCallbacks[key] = callback

proc removeScoreboardChangedCallback*(key: string) =
  if not scoreboardChangedCallbacks.hasKey(key):
    print "removeScoreboardChangedCallback: callback not found:", key
    return
  scoreboardChangedCallbacks.del(key)

let emptyResultHandler = proc(result: PDResult[PDScoresList]) = discard
proc refreshBoard(boardId: BoardId, resultHandler: PDResult[PDScoresList] -> void = emptyResultHandler) =
  let resultCode = playdate.scoreboards.getScores(boardId) do (scoresList: PDResult[PDScoresList]) -> void:
    boardId.decreaseLoadingCount()
    case scoresList.kind
    of PDResultSuccess: 
      print "===== NETWORK Scores OK", $scoresList.result
      scoreboardsCache.setScoreboard(scoresList.result)
      for callback in scoreboardChangedCallbacks.values:
        callback(boardId)
    of PDResultError: 
      print "===== NETWORK Scores ERROR", scoresList.message

    resultHandler(scoresList)

  boardId.increaseLoadingCount()
  print "===== NETWORK Scores START", boardId, $resultCode

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


proc submitScore*(boardId: BoardId, score: uint32) =
  if not validBoardIds.contains(boardId):
    print "Not submitting levelprogress to Scoreboards.'" & boardId.repr &  "'is not a valid board id"
    return
  if not shouldSubmitScore(boardId, score):
    print "Not submitting levelprogress to Scoreboards. Score is not in top 10 or not higher than current score"
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

proc submitLeaderboardScore*(score: uint32) =
  submitScore(LEADERBOARD_BOARD_ID, score)

proc initScoreboardsService() =
  # validBoardIds = dummyScoreboards.keys.toSeq
  validBoardIds = collect(newSeq):
    for levelMeta in officialLevels.values:
      if levelMeta.scoreboardId != "":
        levelMeta.scoreboardId
  validBoardIds.add(LEADERBOARD_BOARD_ID)

proc updateNextOutdatedBoard*() =
  let timeThresholdSeconds = playdate.system.getSecondsSinceEpoch().seconds - 3600
  for board in getScoreboards():
    if board.lastUpdated > timeThresholdSeconds:
      continue  
    refreshBoard(board.boardId, proc (result: PDResult[PDScoresList]) =
      if result.kind == PDResultSuccess:
        updateNextOutdatedBoard()
      else:
        print "Sequential scoreboard update aborted due to failure"
        fetchAllInProgress = false
    )
    return

  # all boards are up to date
  print "All boards are up to date"
  fetchAllInProgress = false

proc fetchAllScoreboards*() =
  if fetchAllInProgress:
    print "fetchAllScoreboards: already in progress"
    return
  fetchAllInProgress = true
  updateNextOutdatedBoard()

initScoreboardsService()
{.push raises: [].}

import std/seqUtils
import std/deques
import std/tables
import std/options
import std/sugar
import playdate/api
import scoreboards_types
export scoreboards_types
import level_meta/level_data
import scoreboards_dummy_data_source
import scoreboards_memory_data_source
import data_store/user_profile
import common/shared_types
import common/utils

const 
  useDummyBoards = true
  REFRESH_TIME_THRESHOLD_SECONDS: uint32 = 3600
    ## Time in seconds after which a scoreboard is considered outdated and should be refreshed

var
  validBoardIds: seq[string] = @[]
  boardLoadingCounts = initTable[string, uint32]()
  fetchAllDeque: Deque[BoardId] = initDeque[BoardId]()
    ## Deque of boardIds that need to be fetched.
    ## Boards stay in the deque until the fetch is complete or fails.
    ## The first board in the deque is the one currently being fetched.
  scoreboardChangedCallbacks: Table[string, ScoreboardChangedCallback] = initTable[string, ScoreboardChangedCallback]()

proc increaseLoadingCount(boardId: BoardId) =
  boardLoadingCounts[boardId] = boardLoadingCounts.getOrDefault(boardId, 0) + 1

proc decreaseLoadingCount(boardId: BoardId) =
  boardLoadingCounts[boardId] = boardLoadingCounts.getOrDefault(boardId, 0) - 1


proc getScoreBoard*(boardId: BoardId): Option[PDScoresList] =
  return scoreboardsCache.getScoreboard(boardId)

proc getScoreboardStates*(): seq[ScoreboardState] =
  return validBoardIds.map(proc (boardId: BoardId): ScoreboardState = 
    if boardLoadingCounts.getOrDefault(boardId, 0) > 0 or fetchAllDeque.contains(boardId):
      # print "getScoreboardStates: Loading", boardId
      return ScoreboardState(
        boardId: boardId,
        kind: ScoreboardStateKind.Loading
      )
    else:
      let board = getScoreBoard(boardId)
      if board.isNone or board.get.scores.len == 0:
        # print "getScoreboardStates: Error", boardId
        return ScoreboardState(
          boardId: boardId,
          kind: ScoreboardStateKind.Error
        )
      else:
        # print "getScoreboardStates: Loaded", boardId
        return ScoreboardState(
          boardId: boardId,
          kind: ScoreboardStateKind.Loaded, scores: board.get
        )
  )

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

proc notifyScoreboardsChanged() =
  for callback in scoreboardChangedCallbacks.values:
    callback()

let emptyResultHandler = proc(result: PDResult[PDScoresList]) = discard
proc refreshBoard(boardId: BoardId, resultHandler: PDResult[PDScoresList] -> void = emptyResultHandler) =
  let resultCode = playdate.scoreboards.getScores(boardId) do (scoresListResult: PDResult[PDScoresList]) -> void:
    boardId.decreaseLoadingCount()
    case scoresListResult.kind
    of PDResultSuccess:
      let scoresList = scoresListResult.result
      print "===== NETWORK Scores OK", $scoresList
      scoreboardsCache.setScoreboard(scoresList)
      if scoresList.scores.len == 10:
        setPlayerName(scoresList.scores[9].player)
    of PDResultError: 
      print "===== NETWORK Scores ERROR", scoresListResult.message
    of PDResultUnavailable:
      print "===== NETWORK Scores UNAVAILABLE", boardId

    # Notify all listeners, also when the board is not updated
    # So that they can update their UI with data or a failure message
    notifyScoreboardsChanged()

    resultHandler(scoresListResult)

  boardId.increaseLoadingCount()
  notifyScoreboardsChanged()
  print "===== NETWORK Scores START", boardId, $resultCode

proc shouldSubmitScore(boardId: BoardId, score: uint32): bool =
  let board = getScoreBoard(boardId)
  if board.isNone:
    return true
  if getPlayerName().isNone:
    # we don't know the current player name, so we can't compare new score to old scores
    return true
  let playerName = getPlayerName().get
  let scores = board.get.scores
  let optOldPlayerScore = scores.findFirst(it => it.player == playerName)
  if optOldPlayerScore.isNone:
    # player has no score yet
    return true
  if score <= optOldPlayerScore.get.value:
    print fmt"Not submitting score to Scoreboards for {boardId}. Score {score} is not higher than current score {optOldPlayerScore.get.value}"
    return false

  return true


proc submitScore*(boardId: BoardId, score: uint32, force: bool = false): bool {.discardable.} =
  ## Returns true when a score submit is enqueued, false when it is discarded
  
  if not validBoardIds.contains(boardId):
    print fmt"Not submitting score to Scoreboards. {boardId} is not a valid board id"
    return false
  if not shouldSubmitScore(boardId, score) and not force:
    return false

  let resultCode = playdate.scoreboards.addScore(boardId, score) do (score: PDResult[PDScore]) -> void:
    boardId.decreaseLoadingCount()
    case score.kind
    of PDResultSuccess:
      print "===== NETWORK addScore OK for " & boardId.repr, score.result.repr
      setPlayerName(score.result.player)
      refreshBoard(boardId)
    of PDResultUnavailable: 
      print "==== NETWORK addScore UNAVAILABLE for " & boardId.repr, ": Probably no Wi-Fi"
    of PDResultError: 
      print "==== NETWORK addScore ERROR for " & boardId.repr, ": ", score.message

  boardId.increaseLoadingCount()
  print "===== NETWORK addScore START", boardId, score, resultCode
  return true

proc submitLeaderboardScore*(score: uint32) =
  submitScore(LEADERBOARD_BOARD_ID, score)

proc initScoreboardsService() =
  if useDummyBoards:
    validBoardIds = dummyScoreboards.keys.toSeq
    scoreboardsCache.setScoreboards(dummyScoreboards)
  else:
    validBoardIds = collect(newSeq):
      for levelMeta in officialLevels.values:
        if levelMeta.scoreboardId != "":
          levelMeta.scoreboardId
    validBoardIds.add(LEADERBOARD_BOARD_ID)
    scoreboardsCache.createScoreboards(validBoardIds)

proc updateNextOutdatedBoard*(finishCallback: VoidCallback = noOp) =
  if fetchAllDeque.len == 0:
    # all boards are up to date
    print "All boards are up to date"
    finishCallback()
    return

  let boardId = fetchAllDeque.popFirst()
  refreshBoard(boardId, proc (result: PDResult[PDScoresList]) =
    if result.kind == PDResultError:
      print "Sequential scoreboard update aborted due to failure"
      fetchAllDeque.clear()
    else:
      updateNextOutdatedBoard(finishCallback)
  )

proc fetchAllScoreboards*(ignoreTimeThreshold: bool = false, finishCallback: VoidCallback = noOp) =
  ## Fetch all scoreboards that are outdated
  ## If ignoreTimeThreshold is true, all scoreboards will be fetched
  ## Otherwise only scoreboards that are older than REFRESH_TIME_THRESHOLD_SECONDS will be fetched
  ## If a refresh is already in progress, this function will do nothing. Even if ignoreTimeThreshold is true
  
  if fetchAllDeque.len > 0:
    print "fetchAllScoreboards: already in progress"
    return
  
  let timeThresholdSeconds = playdate.system.getSecondsSinceEpoch().seconds - REFRESH_TIME_THRESHOLD_SECONDS
  let scoreboards = scoreboardsCache.getScoreboards.values.toSeq
  for board in scoreboards:
    if board.lastUpdated > timeThresholdSeconds and not ignoreTimeThreshold:
      continue
    fetchAllDeque.addLast(board.boardID)
  updateNextOutdatedBoard(finishCallback)

initScoreboardsService()
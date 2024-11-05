{.push raises: [].}

import std/options
import std/sugar
import std/tables
import std/sequtils
import playdate/api
import navigation/[screen, navigator]
import level_meta/level_data
import leaderboards_types, leaderboards_view
import scoreboards/scoreboards_types
import scoreboards/scoreboards_service
import common/utils
import common/score_utils
import data_store/user_profile

const 
  LEADERBOARDS_SCOREBOARD_UPDATED_CALLBACK_KEY = "LeaderboardsScreenScoreboardUpdatedCallbackKey"

proc newLeaderboardsScreen*(initialLeaderboardIdx: int = 0, initialBoardId: BoardId = ""): LeaderboardsScreen =
  LeaderboardsScreen(
    screenType: ScreenType.Leaderboards,
    currentLeaderboardIdx: initialLeaderboardIdx,
    initialBoardId: initialBoardId,
    isDirty: true
  )

proc toLeaderboard*(scoreboard: PDScoresList): Leaderboard =
  let optLevelMeta = getMetaByBoardId(scoreboard.boardID)
  let boardName = if scoreboard.boardId == LEADERBOARD_BOARD_ID:
    "Leaderboard"
  elif optLevelMeta.isNone:
    print "ERROR: Could not find level meta for boardID: ", scoreboard.boardID
    return default(Leaderboard)
  else:
    optLevelMeta.get.name

  let maxScore = if scoreboard.boardId == LEADERBOARD_BOARD_ID:
    let numScoreboards = officialLevels.values.toSeq.filterIt(it.scoreboardId.len > 0).len.uint32
    SCOREBOARDS_MAX_SCORE * numScoreboards
  else:
    SCOREBOARDS_MAX_SCORE

  let playerName = getPlayerName()

  Leaderboard(
    boardID: scoreboard.boardID,
    boardName: boardName,
    scores: scoreboard.scores.mapIt(
      LeaderboardScore(
        rank: it.rank,
        player: it.player,
        isCurrentPlayer: some(it.player) == playerName,
        timeString: scoreToTimeString(score = it.value, maxScore = maxScore)
      )
    )
  )

proc currentLeaderboard(screen: LeaderboardsScreen): Leaderboard {.inline.} =
  screen.leaderboards[screen.currentLeaderboardIdx]

proc refreshLeaderboards*(screen: LeaderboardsScreen) =
  let scoreboards = getScoreboards()
  screen.leaderboards = scoreboards.mapIt(it.toLeaderboard())
  if screen.currentLeaderboardIdx > screen.leaderboards.high:
    screen.currentLeaderboardIdx = screen.leaderboards.high
  if screen.currentLeaderboardPageIdx > screen.currentLeaderboard.scores.high div LEADERBOARDS_PAGE_SIZE:
    screen.currentLeaderboardPageIdx = screen.currentLeaderboard.scores.high div LEADERBOARDS_PAGE_SIZE
  screen.isDirty = true

proc updateInput(screen: LeaderboardsScreen) =
  let buttonState = playdate.system.getButtonState()

  if kButtonUp in buttonState.pushed:
    screen.currentLeaderboardIdx -= 1
    if screen.currentLeaderboardIdx < 0:
      screen.currentLeaderboardIdx = screen.leaderboards.high
    screen.isDirty = true
  elif kButtonDown in buttonState.pushed:
    screen.currentLeaderboardIdx += 1
    if screen.currentLeaderboardIdx > screen.leaderboards.high:
      screen.currentLeaderboardIdx = 0
    screen.isDirty = true
  elif kButtonRight in buttonState.pushed:
    screen.currentLeaderboardPageIdx += 1
    if screen.currentLeaderboard.scores.high > screen.currentLeaderboardPageIdx * LEADERBOARDS_PAGE_SIZE:
      screen.isDirty = true
    else:
      screen.currentLeaderboardPageIdx -= 1
  elif kButtonLeft in buttonState.pushed:
    if screen.currentLeaderboardPageIdx > 0:
      screen.currentLeaderboardPageIdx -= 1
      screen.isDirty = true
    else:
      popScreen()
  elif kButtonA in buttonState.pushed:
    let leaderboard = screen.currentLeaderboard
    let score = leaderboard.scores[screen.currentLeaderboardPageIdx * LEADERBOARDS_PAGE_SIZE]
    if score.isCurrentPlayer:
      print "You are already on the leaderboard"
    else:
      submitLeaderboardScore(score.rank)
      screen.isDirty = true
  elif kButtonB in buttonState.pushed:
    popScreen()

method resume*(screen: LeaderboardsScreen) =
  refreshLeaderboards(screen)
  if screen.initialBoardId.len > 0:
    let (idx, _) = screen.leaderboards.findFirstIndexed(it => it.boardId == screen.initialBoardId)
    if idx >= 0:
      screen.currentLeaderboardIdx = idx
      screen.initialBoardId = "" # clear it, don't re-select on future resumes
    else:
      print "ERROR: Could not find initial boardId: ", screen.initialBoardId
      screen.currentLeaderboardIdx = screen.leaderboards.high # leaderboard is at end

  screen.draw(forceRedraw = true)
  addScoreboardChangedCallback(
    LEADERBOARDS_SCOREBOARD_UPDATED_CALLBACK_KEY,
    proc(boardId: BoardId) = screen.refreshLeaderboards)

method pause*(screen: LeaderboardsScreen) =
  removeScoreboardChangedCallback(LEADERBOARDS_SCOREBOARD_UPDATED_CALLBACK_KEY)

method destroy*(screen: LeaderboardsScreen) =
  pause(screen)
  

method update*(screen: LeaderboardsScreen): int =
  updateInput(screen)
  draw(screen)
  screen.isDirty = false
  return 1

method getRestoreState*(screen: LeaderboardsScreen): Option[ScreenRestoreState] =
  return some(ScreenRestoreState(
    screenType: ScreenType.Leaderboards,
    currentLeaderboardIdx: screen.currentLeaderboardIdx,
  ))
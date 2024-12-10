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
import data_store/game_result_updater

const 
  LEADERBOARDS_SCOREBOARD_UPDATED_CALLBACK_KEY = "LeaderboardsScreenScoreboardUpdatedCallbackKey"

proc newLeaderboardsScreen*(initialLeaderboardIdx: int = 0, initialBoardId: BoardId = ""): LeaderboardsScreen =
  LeaderboardsScreen(
    screenType: ScreenType.Leaderboards,
    currentLeaderboardIdx: initialLeaderboardIdx,
    initialBoardId: initialBoardId,
    isDirty: true
  )

proc currentLeaderboard(screen: LeaderboardsScreen): Leaderboard {.inline.} =
  screen.leaderboards[screen.currentLeaderboardIdx]

{.warning[UnusedImport]: off.}
proc popScreen() =
  print "ERROR: use popScreen(screen: LeaderboardsScreen) instead"
{.warning[UnusedImport]: on.}

proc popScreen(screen: LeaderboardsScreen) =
  let optLevelMeta = getMetaByBoardId(screen.currentLeaderboard().boardId)
  optLevelMeta.map(proc (it: LevelMeta) = 
    setResult(ScreenResult(screenType: ScreenType.LevelSelect, selectPath: it.path))
  )
  navigator.popScreen()

proc toLeaderboardState*(scoreboardState: ScoreboardState): LeaderboardState =
  case scoreboardState.kind:
  of ScoreboardStateKind.Loaded:
    let scores = scoreboardState.scores
    let playerName = getPlayerName()
    let maxScore = if scoreboardState.boardId == LEADERBOARD_BOARD_ID:
      let numScoreboards = officialLevels.values.toSeq.filterIt(it.scoreboardId.len > 0).len.uint32
      SCOREBOARDS_MAX_SCORE * numScoreboards
    else:
      SCOREBOARDS_MAX_SCORE

    let leaderboardScores = scores.scores.mapIt(
      LeaderboardScore(
        rank: it.rank,
        player: it.player,
        isCurrentPlayer: some(it.player) == playerName,
        timeString: scoreToTimeString(score = it.value, maxScore = maxScore)
      )
    )
    return LeaderboardState(
      kind: LeaderboardStateKind.Loaded,
      scores: leaderboardScores
    )
  of ScoreboardStateKind.Loading:
    return LeaderboardState(
      kind: LeaderboardStateKind.Loading,
      position: scoreboardState.position
    )
  of ScoreboardStateKind.Error:
    return LeaderboardState(
      kind: LeaderboardStateKind.Error
    )

proc toLeaderboard*(scoreboard: ScoreboardState): Leaderboard =
  let optLevelMeta = getMetaByBoardId(scoreboard.boardId)
  let boardName = if scoreboard.boardId == LEADERBOARD_BOARD_ID:
    "Leaderboard"
  elif optLevelMeta.isNone:
    print "ERROR: Could not find level meta for boardID: ", scoreboard.boardId
    return default(Leaderboard)
  else:
    optLevelMeta.get.name

  Leaderboard(
    boardId: scoreboard.boardId,
    boardName: boardName,
    state: scoreboard.toLeaderboardState()
  )

proc selectPageContainingPlayer(screen: LeaderboardsScreen) =
  if screen.currentLeaderboard.state.kind != LeaderboardStateKind.Loaded:
    screen.currentLeaderboardPageIdx = 0
    return
    
  let (index, _) = screen.currentLeaderboard.state.scores.findFirstIndexed(it => it.isCurrentPlayer)
  if index >= 0:
    screen.currentLeaderboardPageIdx = index div LEADERBOARDS_PAGE_SIZE
  else:
    screen.currentLeaderboardPageIdx = 0

proc scoreIdxHigh(screen: LeaderboardsScreen): int =
  let state = screen.currentLeaderboard.state
  case state.kind:
  of LeaderboardStateKind.Loaded:
    return state.scores.high
  else:
    return -1


proc refreshLeaderboards*(screen: LeaderboardsScreen) =
  let scoreboards = getScoreboardStates()
  screen.leaderboards = scoreboards.mapIt(it.toLeaderboard())
  if screen.currentLeaderboardIdx > screen.leaderboards.high:
    screen.currentLeaderboardIdx = screen.leaderboards.high
  if screen.currentLeaderboardPageIdx > screen.scoreIdxHigh div LEADERBOARDS_PAGE_SIZE:
    screen.currentLeaderboardPageIdx = screen.scoreIdxHigh div LEADERBOARDS_PAGE_SIZE
  selectPageContainingPlayer(screen)
  screen.isDirty = true

proc updateInput(screen: LeaderboardsScreen) =
  let buttonState = playdate.system.getButtonState()

  if kButtonUp in buttonState.pushed:
    screen.currentLeaderboardIdx -= 1
    if screen.currentLeaderboardIdx < 0:
      screen.currentLeaderboardIdx = screen.leaderboards.high
    selectPageContainingPlayer(screen)
    screen.isDirty = true
  elif kButtonDown in buttonState.pushed:
    screen.currentLeaderboardIdx += 1
    if screen.currentLeaderboardIdx > screen.leaderboards.high:
      screen.currentLeaderboardIdx = 0
    selectPageContainingPlayer(screen)
    screen.isDirty = true
  elif kButtonRight in buttonState.pushed:
    screen.currentLeaderboardPageIdx += 1
    if screen.scoreIdxHigh >= screen.currentLeaderboardPageIdx * LEADERBOARDS_PAGE_SIZE:
      screen.isDirty = true
    else:
      screen.currentLeaderboardPageIdx -= 1
  elif kButtonLeft in buttonState.pushed:
    if screen.currentLeaderboardPageIdx > 0:
      screen.currentLeaderboardPageIdx -= 1
      screen.isDirty = true
    else:
      popScreen(screen)
  # elif kButtonA in buttonState.pushed:
  #   let leaderboard = screen.currentLeaderboard
  #   let score = leaderboard.scores[screen.currentLeaderboardPageIdx * LEADERBOARDS_PAGE_SIZE]
  #   if score.isCurrentPlayer:
  #     print "You are already on the leaderboard"
  #   else:
  #     submitLeaderboardScore(score.rank)
  #     screen.isDirty = true
  elif kButtonB in buttonState.pushed:
    popScreen(screen)

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
    selectPageContainingPlayer(screen)

  addScoreboardChangedCallback(
    LEADERBOARDS_SCOREBOARD_UPDATED_CALLBACK_KEY,
    proc(boardId: BoardId) = screen.refreshLeaderboards
  )

  discard playdate.system.addMenuItem("Refresh", proc(menuItem: PDMenuItemButton) =
    fetchAllScoreboards(ignoreTimeThreshold = true, finishCallback = uploadLocalScores)
  )
  discard playdate.system.addMenuItem("Level select", proc(menuItem: PDMenuItemButton) =
    popToScreenType(ScreenType.LevelSelect)
  )

  screen.draw(forceRedraw = true)

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
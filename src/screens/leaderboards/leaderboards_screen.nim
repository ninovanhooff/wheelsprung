{.push raises: [].}

import std/options
import std/sugar
import std/sequtils
import playdate/api
import navigation/[screen, navigator]
import level_meta/level_data
import leaderboards_types, leaderboards_view
import scoreboards/scoreboards_types
import scoreboards/scoreboards_service
import common/utils

proc newLeaderboardsScreen*(initialPageIdx: int = 0, initialBoardId: BoardId = ""): LeaderboardsScreen =
  LeaderboardsScreen(
    screenType: ScreenType.Leaderboards,
    currentPageIdx: initialPageIdx,
    initialBoardId: initialBoardId,
  )

proc toLeaderboardPage*(scoreboard: PDScoresList): LeaderboardPage =
  let optLevelMeta = getMetaByBoardId(scoreboard.boardID)
  let boardName = if scoreboard.boardID == LEADERBOARD_BOARD_ID:
    "Leaderboard"
  elif optLevelMeta.isNone:
    print "ERROR: Could not find level meta for boardID: ", scoreboard.boardID
    return default(LeaderboardPage)
  else:
    optLevelMeta.get.name

    
  LeaderboardPage(
    boardID: scoreboard.boardID,
    boardName: boardName,
    scores: scoreboard.scores
  )

proc refreshLeaderboards*(screen: LeaderboardsScreen) =
  let scoreboards = getScoreboards()
  screen.pages = scoreboards.mapIt(it.toLeaderboardPage())
  if screen.currentPageIdx > screen.pages.high:
    screen.currentPageIdx = screen.pages.high

proc updateInput(screen: LeaderboardsScreen) =
  let buttonState = playdate.system.getButtonState()

  if kButtonUp in buttonState.pushed:
    screen.currentPageIdx -= 1
    if screen.currentPageIdx < 0:
      screen.currentPageIdx = screen.pages.high
    screen.draw()
  elif kButtonDown in buttonState.pushed:
    screen.currentPageIdx += 1
    if screen.currentPageIdx > screen.pages.high:
      screen.currentPageIdx = 0
    screen.draw()
  elif kButtonB in buttonState.pushed or kButtonLeft in buttonState.pushed:
    popScreen()

method resume*(screen: LeaderboardsScreen) =
  refreshLeaderboards(screen)
  if screen.initialBoardId.len > 0:
    let (idx, _) = screen.pages.findFirstIndexed(it => it.boardId == screen.initialBoardId)
    if idx >= 0:
      screen.currentPageIdx = idx
      screen.initialBoardId = "" # clear it, don't re-select on future resumes
    else:
      print "ERROR: Could not find initial boardId: ", screen.initialBoardId
      screen.currentPageIdx = screen.pages.high # leaderboard is at end

  screen.draw(forceRedraw = true)

method update*(screen: LeaderboardsScreen): int =
  updateInput(screen)
  draw(screen)
  return 1

method getRestoreState*(screen: LeaderboardsScreen): Option[ScreenRestoreState] =
  return some(ScreenRestoreState(
    screenType: ScreenType.Leaderboards,
    currentPageIdx: screen.currentPageIdx,
  ))
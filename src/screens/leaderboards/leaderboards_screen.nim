import std/options
import std/tables
import std/sugar
import std/sequtils
import playdate/api
import navigation/[screen, navigator]
import level_meta/level_data
import leaderboards_types, leaderboards_view
import scoreboards/scoreboards_service

proc newLeaderboardsScreen*(initialPageIdx: int32 = 0): LeaderboardsScreen =
  LeaderboardsScreen(
    screenType: ScreenType.Leaderboards,
    currentPageIdx: initialPageIdx
  )

proc refreshLeaderboards*(screen: LeaderboardsScreen) =
  let scoreboards = getScoreboards()
  screen.pages = scoreboards

proc updateInput(screen: LeaderboardsScreen) =
  let buttonState = playdate.system.getButtonState()

  if kButtonB in buttonState.pushed or kButtonLeft in buttonState.pushed:
    popScreen()

method resume*(screen: LeaderboardsScreen) =
  refreshLeaderboards(screen)
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
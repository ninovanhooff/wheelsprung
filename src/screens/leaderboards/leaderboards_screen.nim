import std/options
import playdate/api
import navigation/[screen, navigator]
import leaderboards_types, leaderboards_view

proc newLeaderboardsScreen*(initialPageIdx: int32 = 0): LeaderboardsScreen =
  LeaderboardsScreen(
    screenType: ScreenType.Leaderboards,
    currentPageIdx: initialPageIdx
  )

proc updateInput(screen: LeaderboardsScreen) =
  let buttonState = playdate.system.getButtonState()

  if kButtonB in buttonState.pushed:
    popScreen()

method resume*(screen: LeaderboardsScreen) =
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
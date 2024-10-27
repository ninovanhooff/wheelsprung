import std/sugar
import std/sequtils
import common/utils
import screens/screen_types
import screens/level_select/level_select_screen
import screens/settings/settings_screen
import screens/leaderboards/leaderboards_screen

proc createScreen(screenRestoreState: ScreenRestoreState): Screen =
  case screenRestoreState.screenType
  of ScreenType.Game:
    return newGameScreen(levelPath = screenRestoreState.levelPath)
  of ScreenType.LevelSelect:
    return newLevelSelectScreen()
  of ScreenType.Leaderboards:
    return newLeaderboardsScreen(initialPageIdx = screenRestoreState.currentPageIdx)
  of ScreenType.Settings:
    return newSettingsScreen()
  of ScreenType.GameResult, ScreenType.HitStop:
    print("Cannot Restore: ", screenRestoreState.screenType)
    return nil

proc createBackStack*(screenRestoreStates: seq[ScreenRestoreState]): seq[Screen] =
  return collect(newSeq):
    for it in screenRestoreStates:
      let screen = createScreen(it)
      if not screen.isNil: screen
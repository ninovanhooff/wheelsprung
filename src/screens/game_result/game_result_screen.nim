{. push warning[LockLevel]:off.}
import playdate/api
import navigation/[screen, navigator]
import std/options
import common/graphics_types
import common/shared_types
import common/utils
import common/level_utils
import screens/settings/settings_screen
import screens/screen_types
import data_store/user_profile

type GameResultScreen = ref object of Screen
  gameResult: GameResult
  nextLevelPath: Option[Path]
  isNextEnabled: bool
  hasPersistedResult: bool


proc newGameResultScreen*(gameResult: GameResult): GameResultScreen {.raises: [].} =
  return GameResultScreen(
    gameResult: gameResult,
    nextLevelPath: nextLevelPath(gameResult.levelId),
    screenType: ScreenType.GameResult
  )

proc isNewPersonalBest(gameResult: GameResult): bool =
  let levelProgress = getLevelProgress(gameResult.levelId)
  return gameResult.resultType == GameResultType.LevelComplete and 
    (levelProgress.bestTime.isNone or levelProgress.bestTime.get > gameResult.time)

proc navigateToGameResult*(result: GameResult) =
  newGameResultScreen(result).pushScreen()

proc comparisonTimeString(gameResult: GameResult): string =
  let levelProgress = getLevelProgress(gameResult.levelId)
  if gameResult.resultType == GameResultType.GAME_OVER or levelProgress.bestTime.isNone:
    return ""
  let bestTime = levelProgress.bestTime.get
  return fmt"({formatTime(gameResult.time - bestTime, signed = true)})"

proc unlockText(gameResult: GameResult): string =
  let levelProgress = getLevelProgress(gameResult.levelId)
  if gameResult.resultType == GameResultType.LevelComplete:
    if levelProgress.bestTime.isNone:
      result = "Star unlocked!"
    elif gameResult.isNewPersonalBest:
      result = "New Personal best!"
    elif gameResult.starCollected and not levelProgress.hasCollectedStar:
      result = "Star collected!"

proc displayText(gameResultType: GameResultType): string {.raises: [], tags: [].} =
  case gameResultType
  of GameResultType.GameOver:
    return "Game Over"
  of GameResultType.LevelComplete:
    return "Level Complete"

proc drawGameResult(self: GameResultScreen) =
  playdate.graphics.clear(kColorWhite)
  let gameResult = self.gameResult
  gfx.drawTextAligned(gameResult.resultType.displayText, 200, 80)
  let timeString = fmt"Your time: {formatTime(gameResult.time)} {comparisonTimeString(gameResult)}"
  gfx.drawTextAligned(timeString, 200, 120)
  gfx.drawTextAligned(gameResult.unlockText, 200, 140)

  let confirmText = if self.isNextEnabled: "Next" else: "Restart"
  gfx.drawTextAligned("Ⓑ Select level           Ⓐ " & confirmText, 200, 200)
  

proc persistGameResult(gameResult: GameResult) =
  try:
    updateLevelProgress(gameResult)
    saveSaveSlot()
  except:
    print("Failed to persist game result", getCurrentExceptionMsg())

method resume*(self: GameResultScreen) =

  self.isNextEnabled = self.gameResult.isNewPersonalBest


  drawGameResult(self) # once in resume is enough, static screen

  if not self.hasPersistedResult:
    persistGameResult(self.gameResult)
    self.hasPersistedResult = true

  discard playdate.system.addMenuItem("Settings", proc(menuItem: PDMenuItemButton) =
    pushScreen(newSettingsScreen())
  )
  discard playdate.system.addMenuItem("Level select", proc(menuItem: PDMenuItemButton) =
    popToScreenType(ScreenType.LevelSelect)
  )
  discard playdate.system.addMenuItem("Restart level", proc(menuItem: PDMenuItemButton) =
    popScreen()
  )

method update*(self: GameResultScreen): int =
  # no drawing needed here, we do it in resume
  let buttonState = playdate.system.getButtonState()

  if kButtonA in buttonState.pushed:
    if self.isNextEnabled:
      popToScreenType(ScreenType.LevelSelect)
      pushScreen(newGameScreen(self.nextLevelPath.get))
    else:
      print "next not enabled", self.gameResult.resultType == GameResultType.LevelComplete, self.nextLevelPath.isSome, self.gameResult.isNewPersonalBest
      popScreen()
  elif kButtonB in buttonState.pushed:
    popToScreenType(ScreenType.LevelSelect)

  return 0

method `$`*(self: GameResultScreen): string {.raises: [], tags: [].} =
  return "GameResultScreen; type: " & repr(self)

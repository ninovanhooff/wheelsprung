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
import cache/font_cache
import cache/bitmap_cache

type 
  GameResultAction {.pure.} = enum
    LevelSelect, Restart, Next
  GameResultScreen = ref object of Screen
    gameResult: GameResult
    nextLevelPath: Option[Path]
    availableActions: seq[GameResultAction]
    availableActionLabels: seq[string]
    currentActionIndex: int
    hasPersistedResult: bool

var
  timeFont: LCDFont
  buttonFont: LCDFont
  gameOverBG: LCDBitmap

proc initGameResultScreen() =
  if not buttonFont.isNil:
    return # already initialized
  timeFont = getOrLoadFont("fonts/Nontendo-Bold-2x")
  buttonFont = getOrLoadFont("fonts/Nontendo-Bold-2x")
  gameOverBG = getOrLoadBitmap("images/game_result/game-over-bg")


proc newGameResultScreen*(gameResult: GameResult): GameResultScreen {.raises: [].} =
  let availableActions = @[GameResultAction.LevelSelect, GameResultAction.Restart, GameResultAction.Next]
  let nextLabel = if gameResult.resultType == GameResultType.LevelComplete: "Next" else: "Skip"
  let retryLabel = if gameResult.resultType == GameResultType.LevelComplete: "Restart" else: "Retry"
  let availableActionLabels = @["LVL SELECT", retryLabel, nextLabel]

  return GameResultScreen(
    gameResult: gameResult,
    availableActions: availableActions,
    availableActionLabels: availableActionLabels,
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
  gameOverBG.draw(0, 0, kBitmapUnflipped)
  let gameResult = self.gameResult
  gfx.drawTextAligned(gameResult.resultType.displayText, 200, 80)
  let timeString = fmt"Your time: {formatTime(gameResult.time)} {comparisonTimeString(gameResult)}"
  gfx.drawTextAligned(timeString, 200, 120)
  gfx.drawTextAligned(gameResult.unlockText, 200, 140)

  gfx.drawTextAligned(self.availableActionLabels[self.currentActionIndex], 100, 210)
  

proc persistGameResult(gameResult: GameResult) =
  try:
    updateLevelProgress(gameResult)
  except:
    print("Failed to persist game result", getCurrentExceptionMsg())

method resume*(self: GameResultScreen) =
  initGameResultScreen()

  gfx.setFont(buttonFont)

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

proc executeAction(self: GameResultScreen, action: GameResultAction) =
  case action
  of GameResultAction.LevelSelect:
    popToScreenType(ScreenType.LevelSelect)
  of GameResultAction.Restart:
    popScreen()
  of GameResultAction.Next:
    if self.nextLevelPath.isSome:
      popToScreenType(ScreenType.LevelSelect)
      pushScreen(newGameScreen(self.nextLevelPath.get))
    else:
      print "next not enabled", self.gameResult.resultType == GameResultType.LevelComplete, self.nextLevelPath.isSome, self.gameResult.isNewPersonalBest
      popScreen()

method update*(self: GameResultScreen): int =
  # no drawing needed here, we do it in resume
  let buttonState = playdate.system.getButtonState()

  if kButtonA in buttonState.pushed:
    executeAction(self, self.availableActions[self.currentActionIndex])
  elif kButtonLeft in buttonState.pushed:
    self.currentActionIndex = rem(self.currentActionIndex - 1, len(self.availableActions))
  elif kButtonRight in buttonState.pushed:
    self.currentActionIndex = rem(self.currentActionIndex + 1, len(self.availableActions))
  elif kButtonB in buttonState.pushed:
    executeAction(self, GameResultAction.LevelSelect)

  drawGameResult(self)
  return 1

method `$`*(self: GameResultScreen): string {.raises: [], tags: [].} =
  return "GameResultScreen; type: " & repr(self)

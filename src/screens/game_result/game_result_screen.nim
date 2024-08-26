{. push warning[LockLevel]:off.}
import playdate/api
import navigation/[screen, navigator]
import std/options
import common/graphics_types
import common/shared_types
import common/utils
import common/level_utils
import common/save_slot_types
import screens/settings/settings_screen
import screens/screen_types
import data_store/user_profile
import cache/font_cache
import cache/bitmap_cache

type 
  GameResultAction {.pure.} = enum
    LevelSelect, Restart, Next
  GameResultScreen = ref object of Screen
    previousProgress: LevelProgress
    gameResult: GameResult
    nextLevelPath: Option[Path]
    availableActions: seq[GameResultAction]
    availableActionLabels: seq[string]
    backgroundImage: LCDBitmap
    currentActionIndex: int
    hasPersistedResult: bool

var
  timeFont: LCDFont
  buttonFont: LCDFont
  newPersonalBestImage: LCDBitmap

proc initGameResultScreen() =
  if not buttonFont.isNil:
    return # already initialized
  timeFont = getOrLoadFont("fonts/Nontendo-Bold-2x")
  buttonFont = getOrLoadFont("fonts/Nontendo-Bold-2x")
  newPersonalBestImage = getOrLoadBitmap("images/game_result/new-personal-best.png")


proc newGameResultScreen*(gameResult: GameResult): GameResultScreen {.raises: [].} =
  let resultType = gameResult.resultType
  let previousProgress = getLevelProgress(gameResult.levelId).copy()
  let availableActions = @[GameResultAction.LevelSelect, GameResultAction.Restart, GameResultAction.Next]
  let nextLabel = if resultType == GameResultType.LevelComplete: "Next" else: "Skip"
  let retryLabel = if resultType == GameResultType.LevelComplete: "Restart" else: "Retry"
  let availableActionLabels = @["LVL SELECT", retryLabel, nextLabel]
  let backgroundImageName = if resultType == GameResultType.GameOver: "game-over-bg" else: "level-complete-bg"
  let backgroundImage = getOrLoadBitmap("images/game_result/" & backgroundImageName)

  print "previousProgress", repr(previousProgress)
    

  return GameResultScreen(
    gameResult: gameResult,
    previousProgress: previousProgress,
    availableActions: availableActions,
    availableActionLabels: availableActionLabels,
    nextLevelPath: nextLevelPath(gameResult.levelId),
    backgroundImage: backgroundImage,
    screenType: ScreenType.GameResult
  )

proc isNewPersonalBest(gameResult: GameResult, previousProgress: LevelProgress): bool =
  
  return gameResult.resultType == GameResultType.LevelComplete and 
    (previousProgress.bestTime.isNone or previousProgress.bestTime.get > gameResult.time)

proc comparisonTimeString(gameResult: GameResult, previousProgress: LevelProgress): string =
  if gameResult.resultType == GameResultType.GAME_OVER or previousProgress.bestTime.isNone:
    return ""
  let bestTime = previousProgress.bestTime.get
  return fmt"{formatTime(gameResult.time - bestTime, signed = true)}"

proc navigateToGameResult*(result: GameResult) =
  newGameResultScreen(result).pushScreen()

proc drawGameOverResult(self: GameResultScreen) =
  let gameResult = self.gameResult
  let timeString = formatTime(gameResult.time)
  gfx.setFont(timeFont)
  gfx.drawTextAligned(timeString, 100, 168)

  gfx.setFont(buttonFont)
  gfx.drawTextAligned(self.availableActionLabels[self.currentActionIndex], 100, 210)

proc drawLevelCompleteResult(self: GameResultScreen) =
  let gameResult = self.gameResult
  if gameResult.isNewPersonalBest(self.previousProgress):
    newPersonalBestImage.draw(9, 142, kBitmapUnflipped)
    
  gfx.setDrawMode(kDrawModeFillWhite)
  let timeString = formatTime(gameResult.time)
  gfx.setFont(timeFont)
  gfx.drawTextAligned(timeString, 135, 110, kTextAlignmentRight)
  let comparisonTimeString = comparisonTimeString(gameResult, self.previousProgress)
  gfx.drawTextAligned(comparisonTimeString, 135, 135, kTextAlignmentRight)

proc drawGameResult(self: GameResultScreen) =
  self.backgroundImage.draw(0, 0, kBitmapUnflipped)
  if self.gameResult.resultType == GameResultType.GameOver:
    drawGameOverResult(self)
  elif self.gameResult.resultType == GameResultType.LevelComplete:
    drawLevelCompleteResult(self)
  

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
      print "next not enabled"
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

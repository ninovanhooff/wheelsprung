{. push warning[LockLevel]:off.}
import playdate/api
import navigation/[screen, navigator]
import std/options
import std/math
import std/sequtils
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
import cache/bitmaptable_cache

type 
  GameResultAction {.pure.} = enum
    LevelSelect, Restart, Next
  GameResultScreen = ref object of Screen
    previousProgress: LevelProgress
    gameResult: GameResult
    nextLevelPath: Option[Path]
    availableActions: seq[GameResultAction]
    backgroundImage: LCDBitmap
    currentActionIndex: int
    hasPersistedResult: bool

var
  timeFont: LCDFont
  buttonFont: LCDFont
  newPersonalBestImage: LCDBitmap
  actionArrowsImageTable: AnnotatedBitmapTable

proc initGameResultScreen() =
  if not buttonFont.isNil:
    return # already initialized
  timeFont = getOrLoadFont("fonts/Nontendo-Bold-2x")
  buttonFont = getOrLoadFont("fonts/Nontendo-Bold-2x")
  newPersonalBestImage = getOrLoadBitmap("images/game_result/new-personal-best.png")
  actionArrowsImageTable = getOrLoadBitmapTable(BitmapTableId.GameResultActionArrows)


proc newGameResultScreen*(gameResult: GameResult): GameResultScreen {.raises: [].} =
  let resultType = gameResult.resultType
  let previousProgress = getLevelProgress(gameResult.levelId).copy()
  let availableActions = @[GameResultAction.LevelSelect, GameResultAction.Restart, GameResultAction.Next]
  let backgroundImageName = if resultType == GameResultType.GameOver: "game-over-bg" else: "level-complete-bg"
  let backgroundImage = getOrLoadBitmap("images/game_result/" & backgroundImageName)

  print "previousProgress", repr(previousProgress)
    

  return GameResultScreen(
    gameResult: gameResult,
    previousProgress: previousProgress,
    availableActions: availableActions,
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

proc label(resultType: GameResultType, gameResultAction: GameResultAction): string =
  case gameResultAction
  of GameResultAction.LevelSelect: return "Level Select"
  of GameResultAction.Restart: return if resultType == GameResultType.LevelComplete: "Restart" else: "Retry"
  of GameResultAction.Next: return if resultType == GameResultType.LevelComplete: "Next" else: "Skip"

proc drawButtons(self: GameResultScreen) =
  let resultType = self.gameResult.resultType
  let availableActionLabels: seq[string] = self.availableActions.mapIt(resultType.label(it))
  
  gfx.setFont(buttonFont)
  gfx.drawTextAligned(availableActionLabels[self.currentActionIndex], 100, 210)

  let buttonState = playdate.system.getButtonState()
  let leftIdx: int32 = if kButtonLeft in buttonState.pushed: 1 else: 0
  let rightIdx: int32 = if kButtonRight in buttonState.pushed: 3 else: 2

  let xOffset = (5 * sin(currentTimeMilliseconds().toFloat * 0.01f)).int32
    
  actionArrowsImageTable.getBitmap(leftIdx).draw(5 + xOffset, 210, kBitmapUnflipped)
  actionArrowsImageTable.getBitmap(rightIdx).draw(172 - xOffset, 210, kBitmapUnflipped)

proc drawGameOverResult(self: GameResultScreen) =
  let gameResult = self.gameResult
  let timeString = formatTime(gameResult.time)
  gfx.setFont(timeFont)
  gfx.drawTextAligned(timeString, 100, 168)

  drawButtons(self)

proc drawLevelCompleteResult(self: GameResultScreen) =
  let gameResult = self.gameResult
  if gameResult.isNewPersonalBest(self.previousProgress):
    newPersonalBestImage.draw(10, 145, kBitmapUnflipped)

  if gameResult.starCollected:
    let starImage = getOrLoadBitmap("images/game_result/acorn")
    starImage.draw(174, 92, kBitmapUnflipped)
    
  gfx.setDrawMode(kDrawModeInverted)
  let timeString = formatTime(gameResult.time)
  gfx.setFont(timeFont)
  gfx.drawTextAligned(timeString, 135, 110, kTextAlignmentRight)
  let comparisonTimeString = comparisonTimeString(gameResult, self.previousProgress)
  gfx.drawTextAligned(comparisonTimeString, 135, 135, kTextAlignmentRight)

  drawButtons(self)

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

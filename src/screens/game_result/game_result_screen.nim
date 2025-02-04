{. push warning[LockLevel]:off.}
import playdate/api
import navigation/[screen, navigator]
import std/options
import std/math
import std/tables
import std/sequtils
import common/graphics_types
import common/shared_types
import common/utils
import common/level_utils
import common/save_slot_types
import common/menu_sounds
import level_meta/level_data
# import screens/settings/settings_screen
import screens/screen_types
import data_store/user_profile
import cache/font_cache
import cache/bitmap_cache
import cache/bitmaptable_cache
import data_store/game_result_updater

type 
  GameResultAction {.pure.} = enum
    LevelSelect, Restart, Next, ShowHints, ShowReplay, ShowEndingCutscene
  GameResultScreen = ref object of Screen
    previousProgress: LevelProgress
    gameResult: GameResult
    nextLevelPath: Option[Path]
    availableActions: seq[GameResultAction]
    backgroundImage: LCDBitmap
    currentActionIndex: int
    hasPersistedResult: bool

const 
  HINT_RETRY_COUNT = 5

var
  timeFont: LCDFont
  buttonFont: LCDFont
  newPersonalBestImage: LCDBitmap
  actionArrowsImageTable: AnnotatedBitmapTable
  hintOfferCount: Table[Path, int] = initTable[Path, int]()
    ## key: level path, value number of times hints have been offered for this level

proc initGameResultScreen() =
  if not buttonFont.isNil:
    return # already initialized
  timeFont = getOrLoadFont("fonts/Nontendo-Bold-2x")
  buttonFont = getOrLoadFont("fonts/Nontendo-Bold-2x")
  newPersonalBestImage = getOrLoadBitmap("images/game_result/new-personal-best.png")
  actionArrowsImageTable = getOrLoadBitmapTable(BitmapTableId.GameResultActionArrows)

proc isNewPersonalBest(gameResult: GameResult, previousProgress: LevelProgress): bool =
  return gameResult.resultType == GameResultType.LevelComplete and
    (previousProgress.bestTime.isNone or previousProgress.bestTime.get > gameResult.time)

proc newGameResultScreen*(gameResult: GameResult): GameResultScreen {.raises: [].} =
  let resultType = gameResult.resultType
  let previousProgress = getLevelProgress(gameResult.levelId).copy()
  let nextPath = nextLevelPath(gameResult.levelId)
  var availableActions = if nextPath.isSome:
    @[GameResultAction.Restart, GameResultAction.Next, GameResultAction.ShowReplay, GameResultAction.LevelSelect]
  else:
    @[GameResultAction.Restart, GameResultAction.ShowReplay, GameResultAction.LevelSelect]

  if gameResult.hintsAvailable and resultType == GameResultType.GameOver:
    # if hints are available, show them as the the first option if they have not been dismissed
    let timesOffered = hintOfferCount.getOrDefault(gameResult.levelId, 0)
    let position = if timesOffered != HINT_RETRY_COUNT: 
      availableActions.len 
    else: 
      0
    availableActions.insert(GameResultAction.ShowHints, position)
    hintOfferCount[gameResult.levelId] = timesOffered + 1

  var currentActionIndex = gameResult.isNewPersonalBest(previousProgress).int32 # if new personal best, select next / level select by default. Else: select restart

  # when the last level ends in victory, show ending cutscene as first option. 
  # If it is a game-over, people who struggle too much might want to see the ending cutscene. So we offer it as the last option
  if nextPath.isNone:
    let position = if resultType == GameResultType.LevelComplete: 0 else: availableActions.len
    availableActions.insert(GameResultAction.ShowEndingCutscene, position)
    if resultType == GameResultType.LevelComplete:
      currentActionIndex = 0
    

  let backgroundImageName = if resultType == GameResultType.GameOver: "game-over-bg" else: "level-complete-bg"
  let backgroundImage = getOrLoadBitmap("images/game_result/" & backgroundImageName)

  # print "previousProgress", repr(previousProgress)
    

  return GameResultScreen(
    gameResult: gameResult,
    previousProgress: previousProgress,
    availableActions: availableActions,
    nextLevelPath: nextPath,
    backgroundImage: backgroundImage,
    currentActionIndex: currentActionIndex,
    screenType: ScreenType.GameResult
  )

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
  of GameResultAction.ShowHints: return "Show hints"
  of GameResultAction.ShowReplay: return "Show replay"
  of GameResultAction.ShowEndingCutscene: return if resultType == GameResultType.LevelComplete: "The End?" else: "Skip"

const buttonTextCenterX = 100

proc drawButtons(self: GameResultScreen) =
  let resultType = self.gameResult.resultType
  let availableActionLabels: seq[string] = self.availableActions.mapIt(resultType.label(it))
  let buttonText = availableActionLabels[self.currentActionIndex]

  gfx.setFont(buttonFont)
  gfx.drawTextAligned(buttonText, buttonTextCenterX, 210)

  let buttonState = playdate.system.getButtonState()
  let pushedOrCurrent = buttonState.pushed + buttonState.current
  let leftIdx: int32 = if kButtonLeft in pushedOrCurrent: 1 else: 0
  let rightIdx: int32 = if kButtonRight in pushedOrCurrent: 1 else: 0

  let xOffset = (4 * sin(currentTimeMilliseconds().float32 * 0.008f)).int32
    
  actionArrowsImageTable.getBitmap(leftIdx).draw(12 + xOffset, 210, kBitmapUnflipped)
  actionArrowsImageTable.getBitmap(rightIdx).draw(178 - xOffset, 210, kBitmapFlippedX)

proc drawGameOverResult(self: GameResultScreen) =
  let gameResult = self.gameResult
  let timeString = formatTime(gameResult.time)
  gfx.setFont(timeFont)
  gfx.drawTextAligned(timeString, 100, 168)

  drawButtons(self)

proc drawLevelCompleteResult(self: GameResultScreen) =
  let gameResult = self.gameResult
  if gameResult.isNewPersonalBest(self.previousProgress):
    newPersonalBestImage.draw(20, 152, kBitmapUnflipped)

  if gameResult.starCollected:
    let starImage = getOrLoadBitmap("images/game_result/acorn")
    starImage.draw(174, 92, kBitmapUnflipped)
    
  gfx.setDrawMode(kDrawModeInverted)
  let timeString = formatTime(gameResult.time)
  gfx.setFont(timeFont)
  gfx.drawTextAligned(timeString, 135, 110, kTextAlignmentRight)
  let comparisonTimeString = comparisonTimeString(gameResult, self.previousProgress)
  gfx.drawTextAligned(comparisonTimeString, 135, 140, kTextAlignmentRight)

  drawButtons(self)

proc drawGameResult(self: GameResultScreen) =
  self.backgroundImage.draw(0, 0, kBitmapUnflipped)
  if self.gameResult.resultType == GameResultType.GameOver:
    drawGameOverResult(self)
  elif self.gameResult.resultType == GameResultType.LevelComplete:
    drawLevelCompleteResult(self)

method resume*(self: GameResultScreen): bool =
  initGameResultScreen()

  gfx.setFont(buttonFont)

  if not self.hasPersistedResult:
    persistGameResult(self.gameResult)
    self.hasPersistedResult = true

  # discard playdate.system.addMenuItem("Settings", proc(menuItem: PDMenuItemButton) =
  #   pushScreen(newSettingsScreen())
  # )
  discard playdate.system.addMenuItem("Level select", proc(menuItem: PDMenuItemButton) =
    popToScreenType(ScreenType.LevelSelect)
  )
  discard playdate.system.addMenuItem("Restart level", proc(menuItem: PDMenuItemButton) =
    popScreen()
  )
  return true

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
  of GameResultAction.ShowHints:
    setResult(ScreenResult(screenType: ScreenType.Game, enableHints: true))
    popScreen()
  of GameResultAction.ShowReplay:
    let inputRecording= self.gameResult.inputRecording
    if inputRecording.isSome:
      pushScreen(newGameScreen(self.gameResult.levelId, inputRecording))
    else:
      print "ERROR: No input recording available"
  of GameResultAction.ShowEndingCutscene:
    # prepare the level select screen to scroll to the first official level after the cutscene ends
    let firstOfficialLevelPath = getFirstOfficialLevelMeta().path
    setResult(ScreenResult(screenType: ScreenType.LevelSelect, selectPath: firstOfficialLevelPath))
    # clear the backstack, leaving only the LevelSelect screen and start ending cutscene
    popToScreenType(ScreenType.LevelSelect)
    pushScreen(newCutSceneScreen(CutsceneId.Ending))

method update*(self: GameResultScreen): int =
  # no drawing needed here, we do it in resume
  let buttonState = playdate.system.getButtonState()

  if kButtonA in buttonState.pushed:
    playConfirmSound()
    executeAction(self, self.availableActions[self.currentActionIndex])
  elif kButtonLeft in buttonState.pushed:
    playSelectPreviousSound()
    self.currentActionIndex = rem(self.currentActionIndex - 1, len(self.availableActions))
  elif kButtonRight in buttonState.pushed:
    playSelectNextSound()
    self.currentActionIndex = rem(self.currentActionIndex + 1, len(self.availableActions))
  elif kButtonB in buttonState.pushed:
    playCancelSound()
    executeAction(self, GameResultAction.LevelSelect)

  drawGameResult(self)
  return 1

method `$`*(self: GameResultScreen): string {.raises: [], tags: [].} =
  return "GameResultScreen; type: " & repr(self.gameResult.resultType) & "; level: " & self.gameResult.levelId

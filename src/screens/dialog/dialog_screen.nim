{. push warning[LockLevel]:off.}
import std/strformat
import playdate/api
import navigation/[screen, navigator]
import graphics_utils
import shared_types
import screens/settings/settings_screen

type DialogScreen = ref object of Screen
  gameResult: GameResult


proc newDialogScreen*(gameResult: GameResult): DialogScreen {.raises: [].} =
  return DialogScreen(gameResult: gameResult)


proc navigateToGameResult*(result: GameResult) =
  newDialogScreen(result).pushScreen()

proc formatTime(time: Seconds): string {.raises: [], tags: [].} =
  try:
    fmt"{time:.2f}"
  except: "unknown time"

proc displayText(gameResultType: GameResultType): string {.raises: [], tags: [].} =
  case gameResultType
  of GameResultType.GameOver:
    return "Game Over"
  of GameResultType.LevelComplete:
    return "Level Complete"

proc drawDialog(self: DialogScreen) =
  playdate.graphics.clear(kColorWhite)
  let gameResult = self.gameResult
  gfx.drawTextAligned(gameResult.resultType.displayText, 200, 80)
  gfx.drawTextAligned("Your time: " & formatTime(gameResult.time), 200, 120)
  if gameResult.resultType == GameResultType.LevelComplete and gameResult.starCollected:
    gfx.drawTextAligned("You collected a star!", 200, 140)

  gfx.drawTextAligned("Ⓑ Select level           Ⓐ Restart", 200, 200)

method resume*(self: DialogScreen) =

  drawDialog(self) # once in resume is enough, static screen
  
  discard playdate.system.addMenuItem("Settings", proc(menuItem: PDMenuItemButton) =
    pushScreen(newSettingsScreen())
  )
  discard playdate.system.addMenuItem("Level select", proc(menuItem: PDMenuItemButton) =
    clearNavigationStack()
  )
  discard playdate.system.addMenuItem("Restart level", proc(menuItem: PDMenuItemButton) =
    popScreen()
  )

method update*(self: DialogScreen): int =
  # no drawing needed here, we do it in resume
  let buttonState = playdate.system.getButtonsState()

  if kButtonA in buttonState.pushed:
    popScreen()
  elif kButtonB in buttonState.pushed:
    clearNavigationStack()
    # navigator will push new level select screen. We cannoto do it here
    # bevause that would create a circular dependency

  return 0

method `$`*(self: DialogScreen): string {.raises: [], tags: [].} =
  return "DialogScreen; type: " & repr(self.gameResult.resultType)

{. push warning[LockLevel]:off.}
import std/strformat
import playdate/api
import navigation/[screen, navigator]
import common/graphics_types
import common/shared_types
import screens/settings/settings_screen

type GameResultScreen = ref object of Screen
  gameResult: GameResult


proc newGameResultScreen*(gameResult: GameResult): GameResultScreen {.raises: [].} =
  return GameResultScreen(
    gameResult: gameResult,
    screenType: ScreenType.GameResult
  )


proc navigateToGameResult*(result: GameResult) =
  newGameResultScreen(result).pushScreen()

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

proc drawGameResult(self: GameResultScreen) =
  playdate.graphics.clear(kColorWhite)
  let gameResult = self.gameResult
  gfx.drawTextAligned(gameResult.resultType.displayText, 200, 80)
  gfx.drawTextAligned("Your time: " & formatTime(gameResult.time), 200, 120)
  if gameResult.resultType == GameResultType.LevelComplete and gameResult.starCollected:
    gfx.drawTextAligned("You collected a star!", 200, 140)

  gfx.drawTextAligned("Ⓑ Select level           Ⓐ Restart", 200, 200)

method resume*(self: GameResultScreen) =

  drawGameResult(self) # once in resume is enough, static screen
  
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
    popScreen()
  elif kButtonB in buttonState.pushed:
    popToScreenType(ScreenType.LevelSelect)

  return 0

method `$`*(self: GameResultScreen): string {.raises: [], tags: [].} =
  return "GameResultScreen; type: " & repr(self.gameResult.resultType)

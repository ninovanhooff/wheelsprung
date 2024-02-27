import std/strformat
import playdate/api
import navigation/[screen, navigator]
import graphics_utils
import utils
import shared_types

type DialogScreen = ref object of Screen
  gameResult: GameResult


proc newDialogScreen*(gameResult: GameResult): DialogScreen {.raises:[].} =
  return DialogScreen(gameResult: gameResult)

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

method resume*(self: DialogScreen) =
  print("DialogScreen resume")
  playdate.graphics.clear(kColorWhite)
  let gameResult = self.gameResult
  gfx.drawTextAligned(gameResult.resultType.displayText, 200,100)
  gfx.drawTextAligned("Your time: " & formatTime(gameResult.time) , 200, 140)

  gfx.drawTextAligned("Ⓑ Select level           Ⓐ Restart", 200, 200)

method update*(self: DialogScreen): int {.locks:0.} =
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

import playdate/api
import navigation/[screen, navigator]
import graphics_utils
import utils

type DialogType* {.pure.} = enum
  GameOver, LevelComplete

type DialogScreen = ref object of Screen
  dialogType: DialogType


proc newDialogScreen*(dialogType: DialogType): DialogScreen {.raises:[].} =
  return DialogScreen(dialogType: dialogType)

proc displayText(dialogType: DialogType): string {.raises: [], tags: [].} =
  case dialogType
  of DialogType.GameOver:
    return "Game Over"
  of DialogType.LevelComplete:
    return "Level Complete"

method resume*(self: DialogScreen) {.locks:0.} =
  print("DialogScreen resume")
  playdate.graphics.clear(kColorWhite)
  discard gfx.drawText(self.dialogType.displayText, 100,100)

method update*(self: DialogScreen): int {.locks:0.} =
  let buttonState = playdate.system.getButtonsState()

  if kButtonA in buttonState.pushed:
    popScreen()

  return 0

method `$`*(self: DialogScreen): string {.raises: [], tags: [].} =
  return "DialogScreen; type: " & repr(self.dialogType)

import playdate/api
import navigation/[screen, navigator]
import graphics_utils
import utils

type DialogScreen = ref object of Screen
  text: string

proc newDialogScreen*(text:string): DialogScreen {.raises:[].} =
  return DialogScreen(text: text)

method resume*(self: DialogScreen) {.locks:0.} =
  print("DialogScreen resume")
  playdate.graphics.clear(kColorWhite)
  discard gfx.drawText(self.text, 100,100)

method update*(self: DialogScreen): int {.locks:0.} =
  let buttonState = playdate.system.getButtonsState()

  if kButtonA in buttonState.pushed:
    popScreen()

  return 0

method `$`*(self: DialogScreen): string {.raises: [], tags: [].} =
  return "DialogScreen text: " & self.text

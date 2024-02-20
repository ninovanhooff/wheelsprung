import playdate/api
import navigation/screen
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

# method update*(self: DialogScreen): int {.locks:0.} =
#   print("DialogScreen update")
#   playdate.graphics.clear(kColorWhite)
#   discard gfx.drawText(self.text, 100,100)
#   return 1

method `$`*(self: DialogScreen): string {.raises: [], tags: [].} =
  return "DialogScreen text: " & self.text

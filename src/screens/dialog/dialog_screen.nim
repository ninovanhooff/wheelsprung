import std/strformat
import playdate/api
import navigation/[screen, navigator]
import graphics_utils
import utils
import shared_types

type DialogType* {.pure.} = enum
  GameOver, LevelComplete

type DialogScreen = ref object of Screen
  dialogType: DialogType
  time: Time


proc newDialogScreen*(dialogType: DialogType, time: Time): DialogScreen {.raises:[].} =
  return DialogScreen(dialogType: dialogType, time: time)

proc formatTime(time: Time): string {.raises: [], tags: [].} =
  try: 
    fmt"{time:.2f}" 
  except: "unknown time"

proc displayText(dialogType: DialogType): string {.raises: [], tags: [].} =
  case dialogType
  of DialogType.GameOver:
    return "Game Over"
  of DialogType.LevelComplete:
    return "Level Complete"

method resume*(self: DialogScreen) =
  print("DialogScreen resume")
  playdate.graphics.clear(kColorWhite)
  gfx.drawTextAligned(self.dialogType.displayText, 200,100)
  gfx.drawTextAligned("Your time: " & formatTime(self.time) , 200, 140)

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
  return "DialogScreen; type: " & repr(self.dialogType)

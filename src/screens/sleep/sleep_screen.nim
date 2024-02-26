import std/strformat
import playdate/api
import navigation/[screen, navigator]
import graphics_utils
import utils
import shared_types

type SleepScreen = ref object of Screen
  nextScreen: Screen
  wakeTime: uint

proc newSleepScreen*(nextScreen: Screen, millis: uint): SleepScreen {.raises:[].} =
  return SleepScreen(
    nextScreen: nextScreen,
    wakeTime: now() + millis
  )

method update*(self: SleepScreen): int {.locks:0.} =
  if now() >= self.wakeTime:
    popScreen() # pop the sleep screen
    pushScreen(self.nextScreen)
  return 0

method `$`*(self: SleepScreen): string {.raises: [].} =
  return "SleepScreen; next: " & $self.nextScreen & "; wakeTime: " & $self.wakeTime

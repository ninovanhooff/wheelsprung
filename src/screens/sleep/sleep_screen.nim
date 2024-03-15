import navigation/[screen, navigator]
import utils

type SleepScreen = ref object of Screen
  nextScreen: Screen
  wakeTime: uint

proc newSleepScreen*(nextScreen: Screen, millis: uint): SleepScreen {.raises:[].} =
  return SleepScreen(
    nextScreen: nextScreen,
    wakeTime: now() + millis
  )

method update*(self: SleepScreen): int =
  if now() >= self.wakeTime:
    popScreen() # pop the sleep screen
    pushScreen(self.nextScreen)
  return 0

method `$`*(self: SleepScreen): string {.raises: [].} =
  return "SleepScreen; next: " & $self.nextScreen & "; wakeTime: " & $self.wakeTime

{.push raises: [].}

import std/sugar
import screen
import utils
import playdate/api

type Navigator = () -> (void)

var backStack: seq[Screen] = @[]
var pendingNavigators: seq[Navigator] = @[]

proc printNavigation(message: string, screen: Screen) =
  print(message & ": " & $screen & "(" & repr(unsafeAddr screen) & ") stack size: " & $backStack.len & " pending.len: " & $pendingNavigators.len)

proc getActiveScreen(): Screen =
  if backStack.len == 0:
    return nil
  else:
    return backStack[^1]

proc popScreenImmediately() =
  let activeScreen = getActiveScreen()
  if activeScreen == nil:
    print("TODO No active screen")
  else:
    printNavigation("Popping screen", activeScreen)
    backStack.del(backStack.high)
    activeScreen.destroy()

proc resumeActiveScreen() =
  let activeScreen = getActiveScreen()
  if activeScreen == nil:
    print("TODO No active screen")
  else:
    printNavigation("Resuming screen", activeScreen)
    activeScreen.resume()

proc pushScreen*(toScreen: Screen) =
  pendingNavigators.add(() => 
    backStack.add(toScreen)
  )

proc popScreen*() =
  pendingNavigators.add(popScreenImmediately)

proc executePendingNavigators() =
  if pendingNavigators.len == 0: return

  let activeScreen = getActiveScreen()  
  for navigation in pendingNavigators:
    navigation()
  pendingNavigators.setLen(0)

  let activeScreenIndex = backStack.find(activeScreen)
  if activeScreen != nil and activeScreenIndex != backStack.high:
    if activeScreenIndex != -1:
      # the activeScreen was moved from the top of the stack to another position
      printNavigation("Pausing screen", activeScreen)
      activeScreen.pause()

  playdate.system.removeAllMenuItems()
  resumeActiveScreen()

proc updateNavigator*(): int =
  executePendingNavigators()
  if backStack.len == 0:
    print("TODO No active screen")
    return 0
  else:
    return getActiveScreen().update()

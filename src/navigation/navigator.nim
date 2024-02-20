{.push raises: [].}

import std/sugar
import screen
import utils
import playdate/api

type Navigator = () -> (void)

var backStack: seq[Screen] = @[]
var pendingNavigators: seq[Navigator] = @[]

proc getActiveScreen(): Screen =
  if backStack.len == 0:
    return nil
  else:
    return backStack[^1]

proc resumeActiveScreen() =
  let activeScreen = getActiveScreen()
  if activeScreen == nil:
    print("TODO No active screen")
  else:
    print("Resuming screen: " & $activeScreen)
    activeScreen.resume()

proc pushScreen*(toScreen: Screen) =
  pendingNavigators.add(() => 
    backStack.add(toScreen)
  )

proc executePendingNavigators() =
  if pendingNavigators.len == 0: return

  let activeScreen = getActiveScreen()  
  for navigation in pendingNavigators:
    navigation()
  pendingNavigators.setLen(0)

  if activeScreen != nil and backStack.find(activeScreen) != backStack.high:
    # the activeScreen was moved from the top of the stack to another position
    print("Pausing screen: " & $activeScreen)
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

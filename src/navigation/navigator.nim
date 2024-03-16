## A simple navigation system for Playdate
## Ported from https://github.com/ninovanhooff/playdate-navigator/blob/a33c2b724dfe7f83d7c406eed3d3aabbb8b550c2/Navigator.lua
{.push raises: [].}

import std/sugar
import screen
import utils
import playdate/api

type Navigator = () -> (void)
type InitialScreenProvider* = () -> (Screen)

var backStack: seq[Screen] = @[]
var pendingNavigators: seq[Navigator] = @[]
var initialScreenProvider: InitialScreenProvider

proc printNavigation(message: string, screen: Screen) =
  print(message & ": " & $screen & " | stack size: " & $backStack.len & " pending.len: " & $pendingNavigators.len)

proc initNavigator*(screenProvider: InitialScreenProvider) =
  initialScreenProvider = screenProvider
  backStack.setLen(0)
  pendingNavigators.setLen(0)

proc getActiveScreen(): Screen =
  if backStack.len == 0:
    return nil
  else:
    return backStack[^1]

proc popScreenImmediately() =
  let activeScreen = getActiveScreen()
  if activeScreen == nil:
    print("TODO popScreenImmediately: No active screen")
  else:
    printNavigation("Popping screen", activeScreen)
    backStack.del(backStack.high)
    activeScreen.destroy()

proc resumeActiveScreen() =
  ## Ensure that the backstack is non-empty and resumes the the screen at the top of the backstack
  ## If the backstack is empty, an Initial Screen will be inserted and an error logged
  
  var activeScreen = getActiveScreen()
  if activeScreen == nil:
    print("resumeActiveScreen: No active screen. Adding initial screen")
    activeScreen = initialScreenProvider()
    backStack.add(activeScreen)
  
  printNavigation("Resuming screen", activeScreen)
  activeScreen.resume()

proc pushScreen*(toScreen: Screen) =
  pendingNavigators.add(() =>
    backStack.add(toScreen)
  )

proc popScreen*() =
  pendingNavigators.add(popScreenImmediately)

proc clearNavigationStack*() =
  pendingNavigators.add(proc() =
    print("Clearing navigation stack")
    while backStack.len > 0:
      popScreenImmediately()
  )

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
    print("TODO updateNavigator: No active screen")
    return 0
  else:
    return getActiveScreen().update()

{.push raises: [].}

import screen
import utils

var backStack: seq[Screen] = @[]
# todo pending navigation operations so that we can handle them in the next frame

proc getActiveScreen*(): Screen =
  return backStack[^1]

proc navigate*(toScreen: Screen) =
  backStack.add(toScreen)
  toScreen.init()
  toScreen.resume()
{.push raises: [].}

import screen

var backStack: seq[Screen] = @[]

proc getActiveScreen*(): Screen =
    return backStack[^1]

proc navigate*(toScreen: Screen) =
    backStack.add(toScreen)
    toScreen.init()
    toScreen.resume()
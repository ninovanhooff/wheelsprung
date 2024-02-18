{.push raises: [].}

import screen

var activeScreen: Screen

proc getActiveScreen*(): Screen =
    return activeScreen

proc navigate*(toScreen: Screen) =
    activeScreen = toScreen
    activeScreen.resume()
    activeScreen.init()
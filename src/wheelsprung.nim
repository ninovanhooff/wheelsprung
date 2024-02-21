import sugar
import std/strutils
import strformat
import ../tests/tests
import utils
import globals
import navigation/[navigator, screen]


import playdate/api
import screens/game/game_screen
import screens/level_select/level_select_screen

const FONT_PATH = "/System/Fonts/Roobert-11-Medium.pft"

var 
    font: LCDFont
    refreshRate = 50.0f

proc update() {.raises: [].} =
    discard updateNavigator()
    playdate.system.drawFPS(0, 0)

proc runCatching(fun: () -> (void), messagePrefix: string=""): void = 
    try:
        fun()
    except:
        let exception = getCurrentException()
        var message: string = ""
        try: 
            message = &"{messagePrefix}\n{getCurrentExceptionMsg()}\n{exception.getStackTrace()}\nFATAL EXCEPTION. STOP."
            # replace line number notation from (90) to :90, which is more common and can be picked up as source link
            message = message.replace('(', ':')
            message = message.replace(")", "")
        except:
            message = getCurrentExceptionMsg() & exception.getStackTrace()

        playdate.system.error(message) # this will stop the program

proc catchingUpdate(): int {.raises: [].} = 
    runCatching(update)
    return 1 ## 1: update display

# This is the application entrypoint and event handler
proc handler(event: PDSystemEvent, keycode: uint) {.raises: [].} =
    if event == kEventInit:
        playdate.display.setRefreshRate(refreshRate)
        playdate.system.randomize() # seed the random number generator

        font = try: playdate.graphics.newFont(FONT_PATH) except: nil
        playdate.graphics.setFont(font)

        runCatching(runTests, "UNIT TESTS FAILED")
        pushScreen(newLevelSelectScreen())
        
        # Set the update callback
        playdate.system.setUpdateCallback(catchingUpdate)
    elif event == kEventKeyReleased:
        if keycode == 116:
            print("T")
            debugDrawLevel = not debugDrawLevel
            print("debugDrawLevel:" & $debugDrawLevel)
        elif keycode == 111:
            print("O")
            debugDrawShapes = not debugDrawShapes
            print("debugDrawShapes:" & $debugDrawShapes)
        elif keycode == 105:
            print("I")
            debugDrawTextures = not debugDrawTextures
            print("debugDrawTextures:" & $debugDrawTextures)
        elif keycode == 99:
            print("C")
            debugDrawConstraints = not debugDrawConstraints
            print("debugDrawConstraints:" & $debugDrawConstraints)
        elif keycode == 106:
            print("J")
            refreshRate -= 5.0f
            playdate.display.setRefreshRate(refreshRate)
            print("refreshRate:" & $refreshRate)
        elif keycode == 108:
            print("L")
            refreshRate += 5.0f
            playdate.display.setRefreshRate(refreshRate)
            print("refreshRate:" & $refreshRate)
        else:
            print("keycode:" & $keycode)
# Used to setup the SDK entrypoint
initSDK()
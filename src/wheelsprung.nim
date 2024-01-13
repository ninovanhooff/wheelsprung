import sugar
import std/strutils
import strformat
import ../tests/tests


import playdate/api
import game/game

const FONT_PATH = "/System/Fonts/Asheville-Sans-14-Bold.pft"

var font: LCDFont

proc update() =
    playdate.graphics.clear(kColorWhite)
    updateChipmunkGame()
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

proc catchingUpdate(): int = 
    runCatching(update)
    return 0

# This is the application entrypoint and event handler
proc handler(event: PDSystemEvent, keycode: uint) {.raises: [].} =
    if event == kEventInit:
        playdate.display.setRefreshRate(50)

        font = try: playdate.graphics.newFont(FONT_PATH) except: nil
        playdate.graphics.setFont(font)

        runCatching(initGame, "initGame FAILED")
        runCatching(runTests, "UNIT TESTS FAILED")

        # Set the update callback
        playdate.system.setUpdateCallback(catchingUpdate)

# Used to setup the SDK entrypoint
initSDK()
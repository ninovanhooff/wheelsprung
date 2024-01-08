import std/strutils
import strformat


import playdate/api
import game/game

const FONT_PATH = "/System/Fonts/Asheville-Sans-14-Bold.pft"

var font: LCDFont

proc update(): int {.cdecl, raises: [].} =
    playdate.graphics.clear(kColorWhite)
    updateChipmunkGame()
    drawChipmunkGame()
    playdate.system.drawFPS(0, 0)
    return 1

proc catchingUpdate(): int = 
    try:
        return update()
    except:
        let exception = getCurrentException()
        var message: string = ""
        try: 
            message = &"{getCurrentExceptionMsg()}\n{exception.getStackTrace()}\nFATAL EXCEPTION. STOP."
            # replace line number notation from (90) to :90, which is more common and can be picked up as source link
            message = message.replace('(', ':')
            message = message.replace(")", "")
        except:
            message = getCurrentExceptionMsg() & exception.getStackTrace()

        playdate.system.error(message) # this will stop the program
        return 0 # code not reached

# This is the application entrypoint and event handler
proc handler(event: PDSystemEvent, keycode: uint) {.raises: [].} =
    if event == kEventInit:
        playdate.display.setRefreshRate(50)

        font = try: playdate.graphics.newFont(FONT_PATH) except: nil
        playdate.graphics.setFont(font)

        try:
            initGame()
        except:
            playdate.system.error(getCurrentExceptionMsg())

        # Set the update callback
        playdate.system.setUpdateCallback(catchingUpdate)

# Used to setup the SDK entrypoint
initSDK()
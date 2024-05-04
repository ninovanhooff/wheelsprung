import sugar
import options
import std/strutils
import strformat
import ../tests/tests
import common/utils
import globals
import data_store/configuration
import data_store/user_profile
import navigation/[navigator, screen]


import playdate/api
import screens/game/game_screen
import screens/level_select/level_select_screen
import screens/settings/settings_screen

const FONT_PATH = "fonts/Roobert-11-Medium.pft"

let initialScreenProvider: InitialScreenProvider = 
  proc(): Screen =
    result = newLevelSelectScreen()

var 
  font: LCDFont

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
      message = &"{messagePrefix}\n{getCurrentExceptionMsg()}\n{exception.getStackTrace()}"
      # replace line number notation from (90) to :90, which is more common and can be picked up as source link
      message = message.replace('(', ':')
      message = message.replace(")", "")
    except:
      message = getCurrentExceptionMsg() & exception.getStackTrace()

    for line in message.splitLines():
      # Log the error to the console, total stack trace might be too long for single call
      playdate.system.logToConsole(line)

proc catchingUpdate(): int {.raises: [].} = 
  runCatching(update)
  return 1 ## 1: update display

# This is the application entrypoint and event handler
proc handler(event: PDSystemEvent, keycode: uint) {.raises: [].} =
  if event == kEventInit:
    discard getSaveSlot() # preload user profile
    playdate.display.setRefreshRate(refreshRate)
    playdate.system.randomize() # seed the random number generator

    font = try: playdate.graphics.newFont(FONT_PATH) except: nil
    playdate.graphics.setFont(font)
    # The color used when the display is drawn at an offset. See HitStopScreen
    playdate.graphics.setBackgroundColor(kColorBlack)


    if defined(debug):
      runCatching(runTests, "UNIT TESTS FAILED")
    initNavigator(initialScreenProvider)
    let lastOpenedLevelPath = getConfig().lastOpenedLevel
    if false:
      pushScreen(newLevelSelectScreen())
    elif lastOpenedLevelPath.isSome and playdate.file.exists(lastOpenedLevelPath.get()):
      pushScreen(newGameScreen(lastOpenedLevelPath.get()))
    else:
      pushScreen(newLevelSelectScreen())
    
    # Set the update callback
    playdate.system.setUpdateCallback(catchingUpdate)
  elif event == kEventTerminate or event == kEventLowPower:
    print("Program will terminate")
    saveSaveSlot()
  elif event == kEventKeyReleased:
    if keycode == 116:
      print("T")
      debugDrawLevel = not debugDrawLevel
      print("debugDrawLevel:" & $debugDrawLevel)
    elif keycode == 103:
      print("G")
      debugDrawGrid = not debugDrawGrid
    elif keycode == 111:
      print("O")
      debugDrawShapes = not debugDrawShapes
      print("debugDrawShapes:" & $debugDrawShapes)
    elif keycode == 112:
      print("P")
      debugDrawPlayer = not debugDrawPlayer
      print("debugDrawPlayers:" & $debugDrawPlayer)
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
  else:
    print("unhandled event:" & $event & " keycode:" & $keycode)
# Used to setup the SDK entrypoint
initSDK()

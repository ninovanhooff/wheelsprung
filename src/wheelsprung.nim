import sugar
import options
import std/strutils
import strformat
import ../tests/tests
import common/utils
import common/shared_types
import globals
import data_store/user_profile
import navigation/[navigator, screen, backstack_builder]
import cache/cache_preloader
import scoreboards/scoreboards_service


import playdate/api
import screens/screen_types
import screens/game/game_screen
import screens/level_select/level_select_screen
import screens/settings/settings_screen
import screens/game_result/game_result_screen

let initialScreenProvider: InitialScreenProvider = 
  proc(): Screen =
    result = newLevelSelectScreen()

var 
  isFirstFrame = true
  frameRate* = NOMINAL_FRAME_RATE
  frameTime: Seconds = 1.0f / frameRate

proc init() {.raises: [].} =
  discard getSaveSlot() # preload user profile
  playdate.display.setRefreshRate(frameRate)
  playdate.system.randomize() # seed the random number generator

  # The color used when the display is drawn at an offset. See HitStopScreen
  playdate.graphics.setBackgroundColor(kColorBlack)

  if defined(debug):
    runTests()

  initNavigator(initialScreenProvider)
  let restoreState = getRestoreState()
  print "restoreState:", restoreState.repr
  if false:
    # pushScreen(newLevelSelectScreen())
    let gameResult = GameResult(
      levelId: "levels/level1.wmj",
      resultType: GameResultType.LevelComplete,
      time: 1840,
      starCollected: true,
    )
    pushScreen(newGameResultScreen(gameResult))
  elif restoreState.get(@[]).len > 0:
    let screens = createBackStack(restoreState.get(@[]))
    replaceBackstack(screens)
  else:
    pushScreen(newLevelSelectScreen())
  


proc update() {.raises: [].} =
  let frameStartTime = getElapsedSeconds()
  discard updateNavigator()
  playdate.system.drawFPS(0, 0)
  # let preloadBudget = lastFrameElapsedSeconds + frameTime - getElapsedSeconds()
  if not isFirstFrame:
    runPreloader(frameStartTime + frameTime)
  isFirstFrame = false

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

    playdate.system.error("FATAL:" & getCurrentExceptionMsg())

proc catchingUpdate(): int {.raises: [].} = 
  runCatching(update)
  return 1 ## 1: update display

proc incrementFrameRate(change: float32) =
  frameRate += change
  frameTime = 1.0f / frameRate
  playdate.display.setRefreshRate(frameRate)
  print("frameRate:" & $frameRate)

# This is the application entrypoint and event handler
proc handler(event: PDSystemEvent, keycode: uint) {.raises: [].} =
  if event == kEventInit:
    runCatching(init)
    
    # Set the update callback
    playdate.system.setUpdateCallback(catchingUpdate)
  elif event == kEventTerminate or event == kEventLowPower:
    if event == kEventLowPower:
      print("Wheelsprung: Low power mode, saving state")
    elif event == kEventTerminate:
      print("Wheelsprung will terminate")
    setRestoreState(createRestoreState())
    saveSaveSlot()
  elif event == kEventUnlock:
    print("Wheelsprung: Unlocked. Refreshing scoreboards")
    fetchAllScoreboards()
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
      incrementFrameRate(-5.0f)
    elif keycode == 108:
      print("L")
      incrementFrameRate(5.0f)
    else:
      print("keycode:" & $keycode)
  elif event == kEventKeyPressed:
    discard
  else:
    print("unhandled event:" & $event & " keycode:" & $keycode)
# Used to setup the SDK entrypoint
initSDK()

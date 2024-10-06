import options
import ../tests/tests
import common/utils
import common/shared_types
import globals
import data_store/user_profile
import navigation/[navigator, screen]


import playdate/api
import screens/screen_types
import screens/game/game_screen
import screens/cutscene/cutscene_screen
import screens/level_select/level_select_screen
import screens/settings/settings_screen
import screens/game_result/game_result_screen

const FONT_PATH = "fonts/Roobert-11-Medium.pft"

let initialScreenProvider: InitialScreenProvider = 
  proc(): Screen =
    result = newLevelSelectScreen()

var 
  font: LCDFont

proc init() {.raises: [].} =
  discard getSaveSlot() # preload user profile
  playdate.display.setRefreshRate(refreshRate)
  playdate.system.randomize() # seed the random number generator

  font = try: playdate.graphics.newFont(FONT_PATH) except: nil
  playdate.graphics.setFont(font)
  # The color used when the display is drawn at an offset. See HitStopScreen
  playdate.graphics.setBackgroundColor(kColorBlack)

  if defined(debug):
    runTests()
  
  initNavigator(initialScreenProvider)
  let lastOpenedLevelPath = getSaveSlot().lastOpenedLevel
  if false: # can be set to true for debugging-convenience
    # pushScreen(newCutSceneScreen())
    let gameResult = GameResult(
      levelId: "levels/level1.wmj",
      resultType: GameResultType.LevelComplete,
      time: 1840,
      starCollected: true,
    )
    pushScreen(newGameResultScreen(gameResult))
  elif lastOpenedLevelPath.isSome and playdate.file.exists(lastOpenedLevelPath.get()):
    pushScreen(newGameScreen(lastOpenedLevelPath.get()))
  else:
    pushScreen(newLevelSelectScreen())

proc update() {.raises: [].} =
  discard updateNavigator()
  playdate.system.drawFPS(0, 0)

proc catchingUpdate(): int {.raises: [].} = 
  runCatching(update)
  return 1 ## 1: update display

# This is the application entrypoint and event handler
proc handler(event: PDSystemEvent, keycode: uint) {.raises: [].} =
  if event == kEventInit:
    return # Do nothing, we want a Lua env for Panels
  elif event == kEventInitLua:
    runCatching(init)
    
    # Set the update callback
    playdate.system.setUpdateCallback(catchingUpdate)
  elif event == kEventTerminate or event == kEventLowPower:
    print("Program will terminate")
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
  elif event == kEventKeyPressed:
    discard
  else:
    print("unhandled event:" & $event & " keycode:" & $keycode)
# Used to setup the SDK entrypoint
initSDK()

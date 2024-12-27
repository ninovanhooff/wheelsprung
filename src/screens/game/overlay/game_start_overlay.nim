import std/options
import common/utils
import common/shared_types
import screens/game/game_types
import screens/game/game_view
import screens/game/sound/game_sound
import screens/game/sound/bike_sound
import game_start_overlay_view
import cache/cache_preloader

const readyEndFrameIdx = 4 # the frame idx in the readyGoBitmapTable that is the last frame before it transforms in to Go!

proc createGameStartOverlayState*(levelName: string): GameStartState =
  let gameStartFrame: int32 = if not getIsGameViewInitialized():
    -3
  elif not getIsGameStartOverlayInitialized():
    -2
  else:
    -1

  return GameStartState(
    gameStartFrame: gameStartFrame,
    readyGoFrame: -1, # will be incremented to 0 in the first frame
    levelName: levelName
  )

proc updateGameStartOverlay*(state: GameState) =
  if state.gameStartState.isNone:
    return

  if state.isGameStarted:
    initGameSound()
    initBikeSound()

  var startState = state.gameStartState.get
  startState.gameStartFrame += 1
  let gameStartFrame = startState.gameStartFrame

  if gameStartFrame == -1:
    initGameView()
  elif gameStartFrame == 0:
    initGameStartOverlay()
    
  if gameStartFrame < 0:
    # do not delay level load, skip first game frame
    return 

  let readyGoFrameCount = getReadyGoFrameCount()
  
  if startState.readyGoFrame >= readyGoFrameCount - 1:
    state.gameStartState = none(GameStartState)
    return

  let frameRepeat = if state.isGameStarted: 2 else: 4

  if startState.readyGoFrame == readyEndFrameIdx and not state.isGameStarted:
    # "Ready?" should be displayed until the game starts
    # While idle, perform preloading
    runPreloader(getElapsedSeconds() + 0.50.Seconds)
    return

  if gameStartFrame mod frameRepeat == 0 and startState.readyGoFrame < readyGoFrameCount - 1:
    startState.readyGoFrame += 1
    

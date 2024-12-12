{. push raises: [].}
import options, sugar
import chipmunk7
import chipmunk_utils
import playdate/api
import common/utils
import data_store/user_profile
import data_store/configuration
import game_level_loader
import game_bike, game_rider, game_ghost
import game_coin, game_star, game_killer, game_finish, game_gravity_zone
import overlay/game_start_overlay
import overlay/game_replay_overlay
import game_terrain
import game_dynamic_object
import game_camera_lerp
import game_camera_pid
import sound/game_sound
import common/shared_types
import game_types, game_constants
import input/game_input
import input/game_input_recording
import game_view
import navigation/navigator
import data_store/game_result_updater
import screens/screen_types
import screens/game_result/game_result_screen
import screens/settings/settings_screen
import screens/hit_stop/hit_stop_screen

const
  restartLevelLabel = "Restart level"
  levelSelectLabel = "Level select"
  settingsLabel = "Settings"
  exitReplayLabel = "Exit replay"

# forward declarations
proc onResetGame(screen: GameScreen) {.raises: [].}

proc setGameResult(state: GameState, resultType: GameResultType, resetGameOnResume: bool = true): GameResult {.discardable.} =
  state.tailRotarySpring.restAngle = 0f
  result = GameResult(
    levelId: state.level.id,
    levelHash: state.level.contentHash,
    resultType: resultType,
    time: state.time,
    starCollected: state.remainingStar.isNone and state.starEnabled and state.level.starPosition.isSome,
    hintsAvailable: (not state.hintsEnabled) and state.level.hintsPath.isSome,
    inputRecording: some(state.inputRecording),
  )
  state.resetGameOnResume = resetGameOnResume
  state.gameResult = some(result)

proc popOrPushGameResult(state: GameState) =
  state.resetGameOnResume = true
  if state.isInReplayMode:
    print "pop game result"
    popScreen()
  else:
    print "push game result"
    navigateToGameResult(state.gameResult.get)

proc enableHints*(state: var GameState) =
  if state.level.hintsPath.isNone:
    print "ERROR: No hints available for this level"
    return
    
  state.background = nil
  state.hintsEnabled = true
  state.initGameBackground()

proc onRestartGamePressed(screen: GameScreen) =
  persistGameResult(screen.state.gameResult.get)
  screen.onResetGame()

proc buildHitStopScreen(state: GameState, collisionShape: Shape): HitStopScreen {.raises: [].} =
  let restartGameHandler = proc() = 
    setResult(ScreenResult(screenType: ScreenType.Game, restartGame: true))
  var screen = createHitstopScreen(state, collisionShape)
  screen.menuItems = @[
    MenuItemDefinition(name: settingsLabel, action: () => pushScreen(newSettingsScreen())),
    MenuItemDefinition(name: levelSelectLabel, action: popScreen),
    MenuItemDefinition(name: restartLevelLabel, action: restartGameHandler),
  ]
  screen.onCanceled = proc(pushed: PDButtons) =
    if kButtonA in pushed:
      state.popOrPushGameResult()
    elif kButtonB in pushed:
      restartGameHandler()
    else:
      print "ERROR cannot handle hitstop cancel for buttons: " & repr(pushed)

  return screen

let removeBikeConstraintsPostStepCallback: PostStepFunc = proc(space: Space, unused: pointer, unused2: pointer) {.cdecl.} =
  # print("removeBikeConstraintsPostStepCallback")
  let state = cast[GameState](space.userData)
  # detach wheels
  state.removeBikeConstraints()

let gameEndedPostStepCallback: PostStepFunc = proc(space: Space, unused: pointer, unused2: pointer) {.cdecl.} =
  # print("gameEndedPostStepCallback")
  let state = cast[GameState](space.userData)
  # make chassis collidable
  addChassisShape(state)
  # Make bike parts bouncy for comec effect
  makeBikeElastic(state)

let gameOverBeginFunc: CollisionBeginFunc = proc(arb: Arbiter; space: Space; unused: pointer): bool {.cdecl.} =
  playCollisionSound()

  let state = cast[GameState](space.userData)
  var
    shapeA: Shape
    shapeB: Shape
  arb.shapes(addr(shapeA), addr(shapeB))

  if state.gameResult.isNone:
    state.setGameResult(GameResultType.GameOver, false)
    if state.isInLiveMode:
      pushScreen(buildHitStopScreen(state, shapeB))
  if state.bikeConstraints.len > 0:
    discard space.addPostStepCallback(removeBikeConstraintsPostStepCallback, removeBikeConstraintsPostStepCallback, nil)
  if state.chassisShape.isNil:
    discard space.addPostStepCallback(gameEndedPostStepCallback, gameEndedPostStepCallback, nil)
  return true # we still want to collide

let finishBeginFunc: CollisionBeginFunc = proc(arb: Arbiter; space: Space; unused: pointer): bool {.cdecl.} =
  let state = cast[GameState](space.userData)
  if state.gameResult.isSome:
    # Can't finish the game if it was already finished
    return false

  if not state.isFinishActivated:
    # print("finish collision but not activated")
    return false
  
  # print("gameWin collision")
  state.setGameResult(GameResultType.LevelComplete)
  playFinishSound()

  # make chassis collidable
  discard space.addPostStepCallback(gameEndedPostStepCallback, gameEndedPostStepCallback, nil)

  return false # don't process the collision further

proc createSpace(level: Level): Space {.raises: [].} =
  let space = newSpace()
  space.iterations = 8
  space.sleepTimeThreshold = 0.5
  # space.collisionSlop = 0.4 # default is 0.1. But since our units are pixels, less that 0.5 pixels should not be noticeable
  # space.idleSpeedThreshold=
  space.gravity = v(0.0, GRAVITY_MAGNITUDE)

  var handler = space.addCollisionHandler(GameCollisionTypes.Coin, GameCollisionTypes.Wheel)
  handler.beginFunc = coinBeginFunc
  handler = space.addCollisionHandler(GameCollisionTypes.Coin, GameCollisionTypes.Head)
  handler.beginFunc = coinBeginFunc
  handler = space.addCollisionHandler(GameCollisionTypes.Star, GameCollisionTypes.Wheel)
  handler.beginFunc = starBeginFunc
  handler = space.addCollisionHandler(GameCollisionTypes.Star, GameCollisionTypes.Head)
  handler.beginFunc = starBeginFunc
  handler = space.addCollisionHandler(GameCollisionTypes.Killer, GameCollisionTypes.Wheel)
  handler.beginFunc = gameOverBeginFunc
  handler = space.addCollisionHandler(GameCollisionTypes.Killer, GameCollisionTypes.Head)
  handler.beginFunc = gameOverBeginFunc
  handler = space.addCollisionHandler(GameCollisionTypes.Terrain, GameCollisionTypes.Head)
  handler.beginFunc = gameOverBeginFunc
  handler = space.addCollisionHandler(GameCollisionTypes.Finish, GameCollisionTypes.Wheel)
  handler.beginFunc = finishBeginFunc
  handler = space.addCollisionHandler(GameCollisionTypes.Finish, GameCollisionTypes.Head)
  handler.beginFunc = finishBeginFunc
  handler = space.addCollisionHandler(GameCollisionTypes.GravityZone, GameCollisionTypes.Wheel)
  handler.beginFunc = gravityZoneBeginFunc
  handler = space.addCollisionHandler(GameCollisionTypes.GravityZone, GameCollisionTypes.Head)
  handler.beginFunc = gravityZoneBeginFunc

  space.addTerrain(level.terrainPolygons)
  space.addTerrain(level.terrainPolylines)
  # cannot add coins here because they are mutable and thus are part of the state, not the level
  if(level.starPosition.isSome):
    space.addStar(level.starPosition.get)
  space.addFinish(level.finish)
      
  return space

proc newGameState(
  level: Level,
  background: LCDBitmap = nil,
  ghostPlayBack: Option[Ghost] = none(Ghost),
  replayInputRecording: Option[InputRecording] = none(InputRecording),
  hintsEnabled: bool = false
): GameState {.raises: [].} =
  let space = level.createSpace()
  let inputProvider: InputProvider = if replayInputRecording.isSome:
    newRecordedInputProvider(replayInputRecording.get)
  else:
    newLiveInputProvider()

  let gameReplayState = if replayInputRecording.isSome:
    some(GameReplayState(
      hideOverlayAt: none(Seconds)
    ))
  else:
    none(GameReplayState)
  
  let state = GameState(
    level: level, 
    gameStartState: some(createGameStartOverlayState(level.meta.name)),
    gameReplayState: gameReplayState,
    background: background,
    hintsEnabled: hintsEnabled,
    space: space,
    gravityDirection: Direction8.D8_DOWN,
    ghostRecording: newGhost(),
    ghostPlayback: ghostPlayBack.get(newGhost()),
    inputRecording: newInputRecording(),
    inputProvider: inputProvider,
    driveDirection: level.initialDriveDirection,
    attitudeAdjust: none[AttitudeAdjust](),
    starEnabled: level.id.isStarEnabled,
  )
  space.userData = cast[DataPointer](state) # Caution: cyclic reference: space -> state -> space
  initGameBike(state)
  let riderPosition = level.initialChassisPosition + riderOffset.transform(state.driveDirection)
  initGameRider(state, riderPosition)
  
  addGameCoins(state)
  addGravityZones(state)
  initGameStar(state)
  state.addDynamicObjects()

  if background.isNil:
    initGameBackground(state)

  state.killers = space.addKillers(level)
  return state

proc onResetGame(screen: GameScreen) =
  # onResetGame(screen.state)
  let oldState = screen.state
  oldState.updateGhostRecording(oldState.coinProgress)
  screen.state = newGameState(
    level = oldState.level,
    background = oldState.background,
    hintsEnabled = oldState.hintsEnabled,
    ghostPlayback = some(pickBestGhost(oldState.ghostRecording, oldState.ghostPlayback))
  )
  oldState.destroy()

  screen.state.updateCameraPid(snapToTarget = true)


proc updateTimers(state: GameState) =
  state.frameCounter += 1
  state.time += timeStep
  let currentTime: Milliseconds = state.time

  if state.gameResult.isSome:
    let gameResult = state.gameResult.get
    let finishTime = gameResult.time
    if currentTime > finishTime + 5000.Milliseconds: # this timeout can be skipped by pressing any button
      state.popOrPushGameResult()

  if state.finishFlipDirectionAt.isSome:
    # apply a torque to the chassis to compensate for the rider's inertia
    state.chassis.torque = state.driveDirection * -15_500.0

    if state.finishFlipDirectionAt.expire(currentTime):
      echo("flip direction timeout")
      state.resetRiderConstraintForces()

  if state.finishTrophyBlinkerAt.expire(currentTime):
    echo("blinker timeout")

proc addMenuItems(gameScreen: GameScreen) =
  if gameScreen.state.isInLiveMode:
    discard playdate.system.addMenuItem(settingsLabel, proc(menuItem: PDMenuItemButton) =
      pushScreen(newSettingsScreen())
    )
    discard playdate.system.addMenuItem(levelSelectLabel, proc(menuItem: PDMenuItemButton) =
      popScreen()
    )
    discard playdate.system.addMenuItem(restartLevelLabel, proc(menuItem: PDMenuItemButton) =
      gameScreen.onResetGame()
    )
  elif gameScreen.state.isInReplayMode:
    discard playdate.system.addMenuItem(exitReplayLabel, proc(menuItem: PDMenuItemButton) =
      popScreen()
    )

### Screen methods

method resume*(gameScreen: GameScreen): bool =
  if gameScreen.state == nil:
    try:
      gameScreen.state = newGameState(loadLevel(gameScreen.levelPath), replayInputRecording = gameScreen.replayInputRecording)
    except Exception as e:
      print "ERROR: Could not load level: " & gameScreen.levelPath
      print e.msg
      return false
  var state = gameScreen.state
  
  gameScreen.addMenuItems()

  resetGameInput(state)

  if state.resetGameOnResume:
    gameScreen.onResetGame()
    state.resetGameOnResume = false

  if not state.isGameStarted:
    if getConfig().getClassicCameraEnabled():
      state.updateCamera(snapToTarget = true)
    else:
      state.updateCameraPid(snapToTarget = true)

  setResult(ScreenResult(screenType: ScreenType.LevelSelect, selectPath: gameScreen.levelPath))
  return true

method pause*(gameScreen: GameScreen) {.raises: [].} =
  pauseGameBike()


method update*(gameScreen: GameScreen): int =
  var state = gameScreen.state
  let liveButtonState = playdate.system.getButtonState()
  handleInput(
    state,
    # by passing the liveButtonState we know we process the button state atomically. 
    # There is no chance that the button state changes between processing here and recording below
    liveButtonState,
    onShowGameResultPressed = proc () = state.popOrPushGameResult(),
    onRestartGamePressed = proc () = gameScreen.onRestartGamePressed(),
  )
  state = gameScreen.state # handleInput might have changed the state if onRestartGamePressed was called
  updateGameStartOverlay(state)
  updateGameReplayOverlay(state)
  updateGameBikeSound(state)

  if state.isGameStarted and not state.isGamePaused:
    updateAttitudeAdjust(state)
    assert state.space.isNil == false
    state.space.step(timeStepSeconds64)
    
    state.ghostRecording.addPose(state)
    if state.isInLiveMode:
      state.inputRecording.addInputFrame(liveButtonState.current, state.frameCounter)

    if not state.isBikeInLevelBounds():
      if not state.gameResult.isSome:
        state.setGameResult(GameResultType.GameOver)
        playScreamSound()
      state.popOrPushGameResult()

    state.updateTimers() # increment for next frame


  if getConfig().getClassicCameraEnabled():
    state.updateCamera()
  else:
    state.updateCameraPid()
  drawGame(addr state) # todo pass as object?
  return 1

method destroy*(gameScreen: GameScreen) =
  gameScreen.pause()
  gameScreen.state.destroy()

method setResult*(gameScreen: GameScreen, screenResult: ScreenResult) =
  if screenResult.screenType != gameScreen.screenType: return
  if screenResult.enableHints:
    gameScreen.state.enableHints()
  if screenResult.restartGame:
    gameScreen.state.resetGameOnResume = true

method getRestoreState*(gameScreen: GameScreen): Option[ScreenRestoreState] =
  if gameScreen.replayInputRecording.isSome:
    # replays are not stored to disk yet,
    # so we can't restore
    return none(ScreenRestoreState)
  return some(ScreenRestoreState(
    screenType: ScreenType.Game,
    levelPath: gameScreen.levelPath,
  ))
  

method `$`*(gameScreen: GameScreen): string =
  return fmt"GameScreen {gameScreen.levelPath}, inputRecording: {gameScreen.replayInputRecording.isSome}" 

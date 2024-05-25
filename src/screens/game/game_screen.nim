{. push warning[LockLevel]:off.}
import options, sugar
import chipmunk7
import chipmunk_utils
import playdate/api
import common/utils
import data_store/user_profile
import game_level_loader
import game_bike, game_rider, game_ghost
import game_coin, game_star, game_killer, game_finish, game_gravity_zone
import game_terrain
import game_dynamic_object
import game_camera
import sound/game_sound
import common/shared_types
import game_types, game_constants
import input/game_input
import game_view
import navigation/[screen, navigator]
import screens/game_result/game_result_screen
import screens/settings/settings_screen
import screens/hit_stop/hit_stop_screen

type GameScreen* = ref object of Screen

const
  restartLevelLabel = "Restart level"
  levelSelectLabel = "Level select"
  settingsLabel = "Settings"

var 
  state: GameState

# forward declarations
proc onResetGame() {.raises: [].}

proc setGameResult(state: GameState, resultType: GameResultType, resetGameOnResume: bool = true): GameResult {.discardable.} =
  result = GameResult(
    levelId: state.level.id,
    resultType: resultType,
    time: state.time,
    starCollected: state.remainingStar.isNone and state.starEnabled and state.level.starPosition.isSome,
  )
  state.resetGameOnResume = resetGameOnResume
  state.gameResult = some(result)

proc updateGameResult(state: GameState) {.raises: [].} =
  if state.gameResult.isSome:
    state.setGameResult(state.gameResult.get.resultType)

proc buildHitStopScreen(state: GameState, collisionShape: Shape): HitStopScreen {.raises: [].} =
  var screen = createHitstopScreen(state, collisionShape)
  screen.menuItems = @[
    MenuItemDefinition(name: settingsLabel, action: () => pushScreen(newSettingsScreen())),
    MenuItemDefinition(name: levelSelectLabel, action: popScreen),
    MenuItemDefinition(name: restartLevelLabel, action: onResetGame),
  ]
  screen.onCanceled = proc() =
    state.resetGameOnResume = true
    navigateToGameResult(state.gameResult.get)

  return screen

let coinPostStepCallback: PostStepFunc = proc(space: Space, coinShape: pointer, unused: pointer) {.cdecl raises: [].} =
  print("coin post step callback")
  let shape = cast[Shape](coinShape)
  print("shape data:" & repr(shape))
  var coin = cast[Coin](shape.userData)
  if state.time < coin.activeFrom:
    print("coin activates at: " & repr(coin.activeFrom) & " current time: " & repr(state.time))
    return
  if coin.count > 1:
    coin.count -= 1
    coin.activeFrom = state.time + 2000.Milliseconds
    print("new count for coin: " & repr(coin))
    playCoinSound(state.coinProgress)
    return

  print("deleting coin: " & repr(coin))
  space.removeShape(shape)
  let deleteIndex = state.remainingCoins.find(coin)
  if deleteIndex == -1:
    print("coin not found in remaining coins: " & repr(coin))
  else:
    print("deleting coin at index: " & repr(deleteIndex))
    state.remainingCoins.delete(deleteIndex)
    playCoinSound(state.coinProgress)

    if state.remainingCoins.len == 0:
      print("all coins collected")
      state.finishTrophyBlinkerAt = some(state.time + 2500.Milliseconds)

let starPostStepCallback: PostStepFunc = proc(space: Space, starShape: pointer, unused: pointer) {.cdecl.} =
  print("star post step callback")
  let shape = cast[Shape](starShape)
  print("shape data:" & repr(shape))
  space.removeShape(shape)
  state.remainingStar = none[Star]()
  state.updateGameResult()
  playStarSound()



let removeBikeConstraintsPostStepCallback: PostStepFunc = proc(space: Space, unused: pointer, unused2: pointer) {.cdecl.} =
  print("shatterBikePostStepCallback")
  # detach wheels
  state.removeBikeConstraints()
  # and make chassis collidable
  discard addChassisShape(state)

let coinBeginFunc: CollisionBeginFunc = proc(arb: Arbiter; space: Space; unused: pointer): bool {.cdecl.} =
  var 
    shapeA: Shape
    shapeB: Shape
  arb.shapes(addr(shapeA), addr(shapeB))
  print("coin collision for arbiter" & " shapeA: " & repr(shapeA) & " shapeB: " & repr(shapeB))
  discard space.addPostStepCallback(coinPostStepCallback, shapeA, nil)
  false # don't process the collision further

let starBeginFunc: CollisionBeginFunc = proc(arb: Arbiter; space: Space; unused: pointer): bool {.cdecl.} =
  var
    shapeA: Shape
    shapeB: Shape
  arb.shapes(addr(shapeA), addr(shapeB))
  discard space.addPostStepCallback(starPostStepCallback, shapeA, nil)
  return false # don't process the collision further

let gameOverBeginFunc: CollisionBeginFunc = proc(arb: Arbiter; space: Space; unused: pointer): bool {.cdecl.} =
  playCollisionSound()

  var
    shapeA: Shape
    shapeB: Shape
  arb.shapes(addr(shapeA), addr(shapeB))

  if state.gameResult.isNone:
    state.setGameResult(GameResultType.GameOver, false)
    pushScreen(buildHitStopScreen(state, shapeB))
  if state.bikeConstraints.len > 0:
    discard space.addPostStepCallback(removeBikeConstraintsPostStepCallback, nil, nil)
  return true # we still want to collide

let finishBeginFunc: CollisionBeginFunc = proc(arb: Arbiter; space: Space; unused: pointer): bool {.cdecl.} =
  if state.gameResult.isSome:
    # Can't finish the game if it was already finished
    return false

  if not state.isFinishActivated:
    print("finish collision but not activated")
    return false
  
  print("gameWin collision")
  state.setGameResult(GameResultType.LevelComplete)
  playFinishSound()

  return false # don't process the collision further

proc createSpace(level: Level): Space {.raises: [].} =
  let space = newSpace()
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
  space.addGravityZones(level.gravityZones)
  if(level.starPosition.isSome):
    space.addStar(level.starPosition.get)
  space.addFinish(level.finishPosition)
      
  return space

proc newGameState(level: Level, background: LCDBitmap = nil, ghostPlayBack: Option[Ghost] = none(Ghost)): GameState {.raises: [].} =
  let space = level.createSpace()
  state = GameState(
    level: level, 
    background: background,
    space: space,
    ghostRecording: newGhost(),
    ghostPlayback: ghostPlayBack.get(newGhost()),
    driveDirection: level.initialDriveDirection,
    attitudeAdjust: none[AttitudeAdjust](),
    starEnabled: level.id.isStarEnabled,
  )
  initGameBike(state)
  let riderPosition = level.initialChassisPosition + riderOffset.transform(state.driveDirection)
  initGameRider(state, riderPosition)
  
  initGameCoins(state)
  initGameStar(state)
  state.adddynamicObjects()

  if background.isNil:
    initGameBackground(state)

  state.killers = space.addKillers(level)
  return state

proc onResetGame() {.raises: [].} =
  state.destroy()
  state.updateGhostRecording(state.coinProgress)
  state = newGameState(
    level = state.level,
    background = state.background,
    ghostPlayback = some(pickBestGhost(state.ghostRecording, state.ghostPlayback))
  )
  resetGameInput(state)

proc updateTimers(state: GameState) =
  state.frameCounter += 1
  state.time += timeStep
  let currentTime: Milliseconds = state.time

  if state.gameResult.isSome:
    let gameResult = state.gameResult.get
    let finishTime = gameResult.time
    if currentTime > finishTime + 5000.Milliseconds: # this timeout can be skipped by pressing any button
      state.resetGameOnResume = true
      navigateToGameResult(gameResult)

  if state.finishFlipDirectionAt.isSome:
    # apply a torque to the chassis to compensate for the rider's inertia
    state.chassis.torque = state.driveDirection * -15_500.0

    if state.finishFlipDirectionAt.expire(currentTime):
      print("flip direction timeout")
      state.resetRiderConstraintForces()

  if state.finishTrophyBlinkerAt.expire(currentTime):
    print("blinker timeout")

proc initGame*(levelPath: string) {.raises: [].} =
  initGameSound()
  initGameView()
  state = newGameState(loadLevel(levelPath))

proc newGameScreen*(levelPath:string): GameScreen {.raises:[].} =
  initGame(levelPath)
  return GameScreen(screenType: ScreenType.Game)

### Screen methods

method resume*(gameScreen: GameScreen) =
  discard playdate.system.addMenuItem(settingsLabel, proc(menuItem: PDMenuItemButton) =
    pushScreen(newSettingsScreen())
  )
  discard playdate.system.addMenuItem(levelSelectLabel, proc(menuItem: PDMenuItemButton) =
    popScreen()
  )
  discard playdate.system.addMenuItem(restartLevelLabel, proc(menuItem: PDMenuItemButton) =
    onResetGame()
  )

  resumeGameView()

  resetGameInput(state)

  if state.resetGameOnResume:
    onResetGame()
    state.resetGameOnResume = false

  if not state.isGameStarted:
    state.updateCamera(snapToTarget = true)
    # the update loop won't draw the game
    drawGame(addr state)

method pause*(gameScreen: GameScreen) {.raises: [].} =
  pauseGameBike()

method update*(gameScreen: GameScreen): int =
  handleInput(state)
  updateGameBikeSound(state) # even when game is not started, we might want to kickstart the engine

  if state.isGameStarted:
    updateAttitudeAdjust(state)
    bench(
      proc() = state.space.step(timeStepSeconds64),
      "space.step",
      50
    )
    
    state.ghostRecording.addPose(state)

    if not state.isBikeInLevelBounds():
      if not state.gameResult.isSome:
        state.setGameResult(GameResultType.GameOver)
        playScreamSound()
      state.resetGameOnResume = true
      navigateToGameResult(state.gameResult.get)

    state.updateTimers() # increment for next frame


  state.updateCamera()
  drawGame(addr state) # todo pass as object?
  return 1

method destroy*(gameScreen: GameScreen) =
  gameScreen.pause()
  state.destroy()

method `$`*(gameScreen: GameScreen): string =
  return "GameScreen"

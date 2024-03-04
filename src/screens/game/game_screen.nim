import options
import chipmunk7
import playdate/api
import utils, chipmunk_utils, graphics_utils
import levels
import game_bike, game_rider, game_coin, game_killer, game_finish, game_terrain
import sound/game_sound
import game_types, shared_types
import game_view
import navigation/[screen, navigator]
import screens/dialog/dialog_screen

type GameScreen* = ref object of Screen

const
  riderOffset = v(-4.0, -18.0) # offset from chassis center
  initialAttitudeAdjustTorque = 90_000.0
  attitudeAdjustAttentuation = 0.75
  attitudeAdjustForceThreshold = 100.0
  maxWheelAngularVelocity = 30.0
  # applied to wheel1 when throttle is pressed
  throttleTorque = 3_500.0
  # applied to both wheels
  brakeTorque = 2_000.0
  timeStep = 1.0f/50.0f

var 
  state: GameState

  # device controls
  actionThrottle = kButtonA
  actionBrake = kButtonB
  actionFlipDirection = kButtonDown
  actionLeanLeft = kButtonLeft
  actionLeanRight = kButtonRight

# simulator overrides
if defined simulator:
  actionThrottle = kButtonUp
  actionBrake = kButtonDown
  actionFlipDirection = kButtonB

# forward declarations
proc onResetGame() {.raises: [].}

proc setGameResult(state: GameState, resultType: GameResultType): GameResult {.discardable.} =
  result = GameResult(
    resultType: resultType,
    time: state.time
  )
  state.resetGameOnResume = true
  state.gameResult = some(result)

proc navigateToGameResult(result: GameResult) =
  newDialogScreen(result).pushScreen()

let coinPostStepCallback: PostStepFunc = proc(space: Space, coinShape: pointer, unused: pointer) {.cdecl.} =
  print("coin post step callback")
  let shape = cast[Shape](coinShape)
  let coinIndex = cast[int](shape.userData)
  print("shape data:" & repr(shape))
  space.removeShape(shape)
  let coinToDelete = state.level.coins[coinIndex]
  print("deleting coin: " & repr(coinToDelete))
  let deleteIndex = state.remainingCoins.find(coinToDelete)
  if deleteIndex == -1:
    print("coin not found in remaining coins: " & repr(coinToDelete))
  else:
    print("deleting coin at index: " & repr(deleteIndex))
    state.remainingCoins.delete(deleteIndex)
    let coinProgress = 1f - (state.remainingCoins.len.float32 / state.level.coins.len.float32)
    print ("coin progress: " & $coinProgress)
    playCoinSound(coinProgress)

    if state.remainingCoins.len == 0:
      print("all coins collected")
      state.finishTrophyBlinkerAt = some(state.time + 2.5.Seconds)


let gameOverPostStepCallback: PostStepFunc = proc(space: Space, unused: pointer, unused2: pointer) {.cdecl.} =
  print("game over post step callback")
  # detach wheels
  state.removeBikeConstraints()
  # and make chassis collidable
  discard addChassisShape(state)

let coinBeginFunc: CollisionBeginFunc = proc(arb: Arbiter; space: Space; unused: pointer): bool {.cdecl.} =
  var 
    shapeA: Shape
    shapeB: Shape
  arb.shapes(addr(shapeA), addr(shapeB))
  print("coin collision for arbiter" & " shapeA: " & repr(shapeA.userData) & " shapeB: " & repr(shapeB.userData))
  discard space.addPostStepCallback(coinPostStepCallback, shapeA, nil)
  false # don't process the collision further

let gameOverBeginFunc: CollisionBeginFunc = proc(arb: Arbiter; space: Space; unused: pointer): bool {.cdecl.} =
  playCollisionSound()
  if state.gameResult.isSome:
    # Can'r be game over if the game was already won
    return true # process collision normally

  state.setGameResult(GameResultType.GameOver)
  discard space.addPostStepCallback(gameOverPostStepCallback, nil, nil)
  return true # we still want to collide

let finishBeginFunc: CollisionBeginFunc = proc(arb: Arbiter; space: Space; unused: pointer): bool {.cdecl.} =
  if state.gameResult.isSome:
    # Can't finish the game if it was already finished
    return false

  if state.remainingCoins.len > 0:
    print("finish collision but not all coins collected")
    return false
  
  print("gameWin collision")
  state.setGameResult(GameResultType.LevelComplete)
  playFinishSound()

  return false # don't process the collision further

proc createSpace(level: Level): Space =
  let space = newSpace()
  space.gravity = v(0.0, 100.0)

  var handler = space.addCollisionHandler(GameCollisionTypes.Coin, GameCollisionTypes.Wheel)
  handler.beginFunc = coinBeginFunc
  handler = space.addCollisionHandler(GameCollisionTypes.Coin, GameCollisionTypes.Head)
  handler.beginFunc = coinBeginFunc
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

  space.addTerrain(level.terrainPolygons)
  space.addCoins(level.coins)
  space.addFinish(level.finishPosition)
      
  return space

proc newGameState(level: Level): GameState =
  let space = level.createSpace()
  state = GameState(
    level: level, 
    space: space,
    driveDirection: level.initialDriveDirection,
  )
  initGameBike(state)
  let riderPosition = level.initialChassisPosition + riderOffset.transform(state.driveDirection)
  initGameRider(state, riderPosition)
  
  initGameCoins(state)
  state.killers = space.addKillers(level)
  return state

proc onResetGame() {.raises: [].} =
  state.destroy()
  state = newGameState(state.level)

proc onThrottle*() =
  let rearWheel = state.rearWheel
  let dd = state.driveDirection
  if rearWheel.angularVelocity * dd > maxWheelAngularVelocity:
    return

  rearWheel.torque = throttleTorque * dd

proc onBrake*() =
  let rearWheel = state.rearWheel
  let frontWheel = state.frontWheel
  rearWheel.torque = -rearWheel.angularVelocity * brakeTorque
  frontWheel.torque = -frontWheel.angularVelocity * brakeTorque

proc onAttitudeAdjust(state: GameState, direction: float) =
  if state.attitudeAdjustForce == 0f:
    state.attitudeAdjustForce = direction * initialAttitudeAdjustTorque

proc onFlipDirection(state: GameState) =
  state.driveDirection *= -1.0
  state.flipBikeDirection()
  let riderPosition = localToWorld(state.chassis, riderOffset.transform(state.driveDirection))
  state.flipRiderDirection(riderPosition)
  state.finishFlipDirectionAt = some(state.time + 0.5.Seconds)

proc updateAttitudeAdjust(state: GameState) =
  let chassis = state.chassis
  if state.attitudeAdjustForce != 0.0:
    chassis.torque = state.attitudeAdjustForce
    state.attitudeAdjustForce *= attitudeAdjustAttentuation
    if state.attitudeAdjustForce.abs < attitudeAdjustForceThreshold:
      state.attitudeAdjustForce = 0f

proc updateTimers(state: GameState) =
  state.time += timeStep
  let currentTime = state.time

  if state.gameResult.isSome:
    let gameResult = state.gameResult.get
    let finishTime = gameResult.time
    if currentTime > finishTime + 2.5.Seconds: # this timeout can be skipped by pressing any button
      navigateToGameResult(gameResult)

  if state.finishFlipDirectionAt.isSome:
    # apply a torque to the chassis to compensate for the rider's inertia
    state.chassis.torque = state.driveDirection * -15_500.0

    if currentTime > state.finishFlipDirectionAt.get:
      state.finishFlipDirectionAt = none[Seconds]()
      state.resetRiderConstraintForces()

  if state.finishTrophyBlinkerAt.isSome:
    if currentTime > state.finishTrophyBlinkerAt.get:
      print("blinker timeout")
      state.finishTrophyBlinkerAt = none[Seconds]()

proc handleInput(state: GameState) =
  state.isThrottlePressed = false

  let buttonsState = playdate.system.getButtonsState()

  if state.gameResult.isSome:
    # when the game is over, the bike cannot be controlled anymore,
    # but any button can be pressed to navigate to the result screen
    if buttonsState.pushed.len > 0:
      navigateToGameResult(state.gameResult.get)
    return


  if actionThrottle in buttonsState.current:
    state.isThrottlePressed = true
    onThrottle()
  if actionBrake in buttonsState.current:
    onBrake()
  
  if actionLeanLeft in buttonsState.current:
    state.onAttitudeAdjust(-1f)
  elif actionLeanRight in buttonsState.current:
    state.onAttitudeAdjust(1f)

  if actionFlipDirection in buttonsState.pushed:
    print("Flip direction pressed")
    state.onFlipDirection()

proc initGame*(levelPath: string) {.raises: [].} =
  state = newGameState(loadLevel(levelPath))
  initGameSound()
  initGameView()

proc newGameScreen*(levelPath:string): GameScreen {.raises:[].} =
  initGame(levelPath)
  return GameScreen()

### Screen methods

method resume*(gameScreen: GameScreen) =
  discard playdate.system.addMenuItem("Level select", proc(menuItem: PDMenuItemButton) =
      popScreen()
  )
  discard playdate.system.addMenuItem("Restart level", proc(menuItem: PDMenuItemButton) =
    onResetGame()
  )

  if state.resetGameOnResume:
    onResetGame()
    state.resetGameOnResume = false

method pause*(gameScreen: GameScreen) {.raises: [].} =
  pauseGameBike()

method update*(gameScreen: GameScreen): int {.locks:0.} =
  handleInput(state)
  state.updateAttitudeAdjust()

  state.space.step(timeStep)
  state.updateTimers()

  updateGameBike(state)
  if not state.isBikeInLevelBounds():
    if not state.gameResult.isSome:
      state.setGameResult(GameResultType.GameOver)
    navigateToGameResult(state.gameResult.get)

  state.camera = state.level.cameraBounds.clampVect(
    state.chassis.position - halfDisplaySize
  ).round()
  drawGame(addr state) # todo pass as object?
  return 1

method destroy*(gameScreen: GameScreen) =
  gameScreen.pause()
  state.destroy()

method `$`*(gameScreen: GameScreen): string =
  return "GameScreen"

import options
import chipmunk7
import playdate/api
import utils, chipmunk_utils, graphics_utils
import levels
import game_bike, game_rider, game_coin, game_killer, game_finish, game_terrain
import game_types
import game_view
import navigation/screen

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
  halfDisplaySize: Vect = v(0.0,0.0)

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

let coinBeginFunc: CollisionBeginFunc = proc(arb: Arbiter; space: Space; unused: pointer): bool {.cdecl.} =
  var 
    shapeA: Shape
    shapeB: Shape
  arb.shapes(addr(shapeA), addr(shapeB))
  print("coin collision for arbiter" & " shapeA: " & repr(shapeA.userData) & " shapeB: " & repr(shapeB.userData))
  discard space.addPostStepCallback(coinPostStepCallback, shapeA, nil)
  false # don't process the collision further

let gameOverBeginFunc: CollisionBeginFunc = proc(arb: Arbiter; space: Space; unused: pointer): bool {.cdecl.} =
  var 
    shapeA: Shape
    shapeB: Shape
  arb.shapes(addr(shapeA), addr(shapeB))
  print("gameOver collision for arbiter" & " shapeA: " & repr(shapeA.userData) & " shapeB: " & repr(shapeB.userData))
  onResetGame()
  false # don't process the collision further

let finishBeginFunc: CollisionBeginFunc = proc(arb: Arbiter; space: Space; unused: pointer): bool {.cdecl.} =
  var 
    shapeA: Shape
    shapeB: Shape
  arb.shapes(addr(shapeA), addr(shapeB))
  print("gameWin collision for arbiter" & " shapeA: " & repr(shapeA.userData) & " shapeB: " & repr(shapeB.userData))
  onResetGame()
  false # don't process the collision further

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
  state = newGameState(state.level)

proc onThrottle*() =
  let rearWheel = state.rearWheel
  let dd = state.driveDirection
  if rearWheel.angularVelocity * dd > maxWheelAngularVelocity:
    print("ignore throttle. back wheel already at max angular velocity")
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
  else:
    print("ignore attitude adjust. Already in progress with remaining force: " & $state.attitudeAdjustForce)

proc onFlipDirection(state: GameState) =
  state.driveDirection *= -1.0
  state.flipBikeDirection()
  let riderPosition = localToWorld(state.chassis, riderOffset.transform(state.driveDirection))
  state.flipRiderDirection(riderPosition)
  state.finishFlipDirectionAt = some(state.time + 0.5f)

proc updateAttitudeAdjust(state: GameState) =
  let chassis = state.chassis
  if state.attitudeAdjustForce != 0.0:
    chassis.torque = state.attitudeAdjustForce
    state.attitudeAdjustForce *= attitudeAdjustAttentuation
    if state.attitudeAdjustForce.abs < attitudeAdjustForceThreshold:
      state.attitudeAdjustForce = 0f

proc updateTimers(state: GameState) =
  state.time += timeStep
  
  if state.finishFlipDirectionAt.isSome:
    # apply a torque to the chassis to compensate for the rider's inertia
    state.chassis.torque = state.driveDirection * -15_500.0

    if state.time > state.finishFlipDirectionAt.get:
      state.finishFlipDirectionAt = none[Time]()
      state.resetRiderConstraintForces()
    

proc handleInput(state: GameState) =
  state.isThrottlePressed = false

  let buttonsState = playdate.system.getButtonsState()

  if actionThrottle in buttonsState.current:
    state.isThrottlePressed = true
    onThrottle()
  if actionBrake in buttonsState.current:
    onBrake()
  
  if actionLeanLeft in buttonsState.current:
    print("Lean left pressed")
    state.onAttitudeAdjust(-1f)
  elif actionLeanRight in buttonsState.current:
    print("Lean Right pressed")
    state.onAttitudeAdjust(1f)

  if actionFlipDirection in buttonsState.pushed:
    print("Flip direction pressed")
    state.onFlipDirection()

proc initGame*(levelPath: string) {.raises: [].} =
  state = newGameState(loadLevel(levelPath))
  halfDisplaySize = getDisplaySize() / 2.0

  initGameView()

proc newGameScreen*(levelPath:string): GameScreen {.raises:[].} =
  initGame(levelPath)
  return GameScreen()

method resume*(gameScreen: GameScreen) =
  discard playdate.system.addMenuItem("Restart level", proc(menuItem: PDMenuItemButton) =
    onResetGame()
  )

method update*(gameScreen: GameScreen): int {.locks:0.} =
  handleInput(state)
  state.updateAttitudeAdjust()

  state.space.step(timeStep)
  state.updateTimers()

  updateGameBike(state)

  state.camera = state.chassis.position - halfDisplaySize
  drawGame(addr state) # todo pass as object?
  return 1

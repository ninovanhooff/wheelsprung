import options
import std/sequtils
import chipmunk7
import playdate/api
import utils, chipmunk_utils, graphics_utils
import levels
import game_bike, game_rider, game_coin
import game_types
import game_view

const
  groundFriction = 10.0
  riderOffset = v(-4.0, -18.0) # offset from chassis center
  initialAttitudeAdjustTorque = 90_000.0
  attitudeAdjustAttentuation = 0.75
  attitudeAdjustForceThreshold = 100.0
  maxWheelAngularVelocity = 30.0
  # applied to wheel1 when throttle is pressed
  throttleTorque = 3_500.0
  # applied to both wheels
  brakeTorque = 2_000.0
  coinRadius = 10.0
  vCoinOffset = v(coinRadius, coinRadius)
  timeStep = 1.0f/50.0f

var state: GameState

# device controls
var actionThrottle = kButtonA
var actionBrake = kButtonB
var actionFlipDirection = kButtonDown
var actionLeanLeft = kButtonLeft
var actionLeanRight = kButtonRight
# simulator overrides
if defined simulator:
  actionThrottle = kButtonUp
  actionBrake = kButtonDown
  actionFlipDirection = kButtonB

let coinPostStepCallback: PostStepFunc = proc(space: Space, key: pointer, data: pointer) {.cdecl.} =
  print("post step callback for space: " & repr(space) & " key: " & repr(key) & " data: " & repr(data))
  let shape = cast[Shape](key)
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

let coinBeginFunc: CollisionBeginFunc = proc(arb: Arbiter; space: Space; data: pointer): bool {.cdecl.} =
  print("coin collision for arbiter: " & repr(arb) & " space: " & repr(space) & " data: " & repr(data))
  print("space locked: " & $space.isLocked)
  var 
    shapeA: Shape
    shapeB: Shape
  arb.shapes(addr(shapeA), addr(shapeB))
  space.addPostStepCallback(coinPostStepCallback, shapeA, nil)

proc createSpace(level: Level): Space =
  let space = newSpace()
  space.gravity = v(0.0, 100.0)

  var handler = space.addCollisionHandler(collisionTypeCoin, collisionTypeWheel)
  handler.beginFunc = coinBeginFunc

  # Add the polygons as segment shapes to the physics space
  for polygon in level.groundPolygons:
    let vects: seq[Vect] = polygon.map(toVect)
    for i in 1..vects.high:
      let shape = newSegmentShape(space.staticBody, vects[i-1], vects[i], 0.0)
      shape.friction = groundFriction
      discard space.addShape(shape)

    for index, coin in level.coins:
      let shape: Shape = newCircleShape(space.staticBody, coinRadius, toVect(coin) + vCoinOffset)
      shape.sensor = true # only detect collisions, don't apply forces to colliders
      shape.collisionType = collisionTypeCoin
      shape.userData = cast[DataPointer](index)
      discard space.addShape(shape)

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
  return state

proc onResetGame() {.raises: [].} =
  state = newGameState(state.level)

proc initGame*() {.raises: [].} =
  state = newGameState(loadLevel("levels/fallbackLevel.json"))

  discard playdate.system.addMenuItem("Restart level", proc(menuItem: PDMenuItemButton) =
    onResetGame()
  )

  initGameView()

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

proc updateChipmunkGame*() {.cdecl, raises: [].} =
  handleInput(state)
  state.updateAttitudeAdjust()

  state.space.step(timeStep)
  state.updateTimers()

  updateGameBike(state)

  state.camera = state.chassis.position - v(playdate.display.getWidth()/2, playdate.display.getHeight()/2)
  drawChipmunkGame(addr state) # todo pass as object?

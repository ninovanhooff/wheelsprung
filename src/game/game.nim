import chipmunk7
import playdate/api
import utils
import levels
import bike_engine, bike_physics
import game_types
import game_view

const
  gravity = v(0, 100)
  initialAttitudeAdjustTorque = 50_000f
  attitudeAdjustAttentuation = 0.8f
  attitudeAdjustForceThreshold = 100f
  maxWheelAngularVelocity = 20f
  # applied to wheel1 and chassis to make bike more unstable
  throttleTorque = 2_000f
  # applied to both wheels
  brakeTorque = 2_000f
  timeStep = 1.0f/50.0f

var state: GameState
var isThrottlePressed = false

# device controls
var actionThrottle = kButtonA
var actionBrake = kButtonB
var actionFlipDirection = kButtonUp
var actionLeanLeft = kButtonLeft
var actionLeanRight = kButtonRight
# simulator overrides
if defined simulator:
  actionThrottle = kButtonUp
  actionBrake = kButtonDown
  actionFlipDirection = kButtonB



proc initGame*() {.raises: [].} =
  let space = loadLevel("levels/fallbackLevel.json")
  space.gravity = gravity
  state = GameState(space: space, driveDirection: DD_RIGHT)
  initBikePhysics(state)
  initBikeEngine()

# proc resetPosition() =
#   wheel1.position = posA
#   wheel1.velocity = vzero
#   wheel1.force = vzero
#   wheel1.angle = 0f
#   wheel1.angularVelocity = 0f
#   wheel1.torque = 0f

#   wheel2.position = posB
#   wheel2.velocity = vzero
#   wheel2.force = vzero
#   wheel2.angle = 0f
#   wheel2.angularVelocity = 0f
#   wheel2.torque = 0f

#   chassis.position = posChassis
#   chassis.velocity = vzero
#   chassis.force = vzero
#   chassis.angle = 0f
#   chassis.angularVelocity = 0f
#   chassis.torque = 0f

proc onThrottle*() =
  let backWheel = state.backWheel
  let dd = state.driveDirection
  if backWheel.angularVelocity * dd > maxWheelAngularVelocity:
    print("ignore throttle. back wheel already at max angular velocity")
    return

  backWheel.torque = throttleTorque * dd
  print("wheel1.torque: " & $backWheel.torque)

proc onBrake*() =
  let backWheel = state.backWheel
  let frontWheel = state.frontWheel
  backWheel.torque = -backWheel.angularVelocity * brakeTorque
  frontWheel.torque = -frontWheel.angularVelocity * brakeTorque
  print("wheel1.torque: " & $backWheel.torque)
  print("wheel2.torque: " & $frontWheel.torque)

proc updateAttitudeAdjust(state: GameState) =
  let chassis = state.chassis
  if state.attitudeAdjustForce != 0f:
    chassis.torque = state.attitudeAdjustForce
    state.attitudeAdjustForce *= attitudeAdjustAttentuation
    if state.attitudeAdjustForce.abs < attitudeAdjustForceThreshold:
      state.attitudeAdjustForce = 0f

proc onAttitudeAdjust(state: GameState, direction: float) =
  if state.attitudeAdjustForce == 0f:
    state.attitudeAdjustForce = direction * initialAttitudeAdjustTorque
  else:
    print("ignore attitude adjust. Already in progress with remaining force: " & $state.attitudeAdjustForce)
    

proc handleInput() =
    isThrottlePressed = false

    let buttonsState = playdate.system.getButtonsState()

    if actionThrottle in buttonsState.current:
      print("Throttle held")
      isThrottlePressed = true
      onThrottle()
    if actionBrake in buttonsState.current:
      print("Brake held")
      onBrake()
    
    if actionLeanLeft in buttonsState.pushed:
      print("Lean left pressed")
      state.onAttitudeAdjust(-1f)
    elif actionLeanRight in buttonsState.pushed:
      print("Lean Right pressed")
      state.onAttitudeAdjust(1f)

    if actionFlipDirection in buttonsState.pushed:
      print("Flip direction pressed")
      state.driveDirection = -state.driveDirection

proc updateChipmunkGame*() {.cdecl, raises: [].} =
  handleInput()
  state.updateAttitudeAdjust()

  state.space.step(timeStep)
  state.time += timeStep

  updateBikeEngine(isThrottlePressed, state.backWheel.angularVelocity * state.driveDirection)

  state.camera = state.chassis.position - v(playdate.display.getWidth()/2, playdate.display.getHeight()/2)
  drawChipmunkGame(addr state)

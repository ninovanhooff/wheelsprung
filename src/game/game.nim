import chipmunk7
import playdate/api
import utils, chipmunk_utils
import levels
import bike_engine, bike_physics
import game_rider
import game_types
import game_view

const
  riderOffset = v(-4.0, -18.0) # offset from chassis center
  initialAttitudeAdjustTorque = 50_000f
  attitudeAdjustAttentuation = 0.7f
  attitudeAdjustForceThreshold = 100f
  maxWheelAngularVelocity = 30.0
  # applied to wheel1 when throttle is pressed
  throttleTorque = 3_000.0
  # applied to both wheels
  brakeTorque = 2_000.0
  timeStep = 1.0f/50.0f

var state: GameState
var isThrottlePressed = false

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



proc initGame*() {.raises: [].} =
  state = loadLevel("levels/fallbackLevel.json")
  initBikePhysics(state)
  let riderPosition = state.initialChassisPosition + riderOffset.transform(state.driveDirection)
  initRiderPhysics(state, riderPosition)
  initBikeEngine()
  initGameView()

proc onThrottle*() =
  let rearWheel = state.rearWheel
  let dd = state.driveDirection
  if rearWheel.angularVelocity * dd > maxWheelAngularVelocity:
    print("ignore throttle. back wheel already at max angular velocity")
    return

  rearWheel.torque = throttleTorque * dd
  print("wheel1.torque: " & $rearWheel.torque)

proc onBrake*() =
  let rearWheel = state.rearWheel
  let frontWheel = state.frontWheel
  rearWheel.torque = -rearWheel.angularVelocity * brakeTorque
  frontWheel.torque = -frontWheel.angularVelocity * brakeTorque
  print("wheel1.torque: " & $rearWheel.torque)
  print("wheel2.torque: " & $frontWheel.torque)

proc onAttitudeAdjust(state: GameState, direction: float) =
  if state.attitudeAdjustForce == 0f:
    state.attitudeAdjustForce = direction * initialAttitudeAdjustTorque
  else:
    print("ignore attitude adjust. Already in progress with remaining force: " & $state.attitudeAdjustForce)

proc onFlipDirection(state: GameState) =
  state.driveDirection *= -1
  state.flipBikeDirection()
  let riderPosition = localToWorld(state.chassis, riderOffset.transform(state.driveDirection))
  state.flipRiderDirection(riderPosition)

proc updateAttitudeAdjust(state: GameState) =
  let chassis = state.chassis
  if state.attitudeAdjustForce != 0f:
    chassis.torque = state.attitudeAdjustForce
    state.attitudeAdjustForce *= attitudeAdjustAttentuation
    if state.attitudeAdjustForce.abs < attitudeAdjustForceThreshold:
      state.attitudeAdjustForce = 0f

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
      state.onFlipDirection()

proc updateChipmunkGame*() {.cdecl, raises: [].} =
  handleInput()
  state.updateAttitudeAdjust()

  state.space.step(timeStep)
  state.time += timeStep

  updateBikeEngine(isThrottlePressed, state.rearWheel.angularVelocity * state.driveDirection)

  state.camera = state.chassis.position - v(playdate.display.getWidth()/2, playdate.display.getHeight()/2)
  drawChipmunkGame(addr state)

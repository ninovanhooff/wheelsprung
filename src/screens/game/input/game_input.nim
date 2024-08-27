{.push raises: [].}
import std/[options, sugar]
import playdate/api
import chipmunk7, chipmunk_utils
import common/utils
import screens/game/[
  game_types, game_constants, game_bike, game_rider
]
import input/input_manager
import common/shared_types
import data_store/configuration
import input/input_response
import screens/game_result/game_result_screen

const
  maxWheelAngularVelocity = 30.0
  minAttitudeAdjustForce = 100.0
  # applied to wheel1 when throttle is pressed
  throttleTorque = 3_500.0
  # applied to both wheels
  brakeTorque = 2_000.0

var
  # device controls
  actionThrottle = kButtonA
  actionBrake = kButtonB
  actionFlipDirection = kButtonDown
  actionLeanLeft = kButtonLeft
  actionLeanRight = kButtonRight

  dPadInputType: DPadInputType
  attitudeInputResponse: (t: Seconds) -> Float

# simulator overrides
if defined simulator:
  actionThrottle = kButtonUp
  actionBrake = kButtonDown
  actionFlipDirection = kButtonB

proc onThrottle(state: GameState) =
  let rearWheel = state.rearWheel
  let dd = state.driveDirection
  if rearWheel.angularVelocity * dd > maxWheelAngularVelocity:
    return

  rearWheel.torque = throttleTorque * dd

proc onBrake(state: GameState) =
  let rearWheel = state.rearWheel
  let frontWheel = state.frontWheel
  rearWheel.torque = -rearWheel.angularVelocity * brakeTorque
  frontWheel.torque = -frontWheel.angularVelocity * brakeTorque

proc setAttitudeAdjust(state: GameState, direction: Float) =
  state.attitudeAdjust = some(AttitudeAdjust(
    direction: direction,
    startedAt: state.time
  ))

proc onButtonAttitudeAdjust(state: GameState, direction: Float) =
  ## Called on every frame, direction may be 0.0 if the button is not pressed
  
  if direction == 0.0:
    if state.attitudeAdjust.isSome:
      state.attitudeAdjust = none(AttitudeAdjust)
      state.resetRiderAttitudePosition()
    return

  let optAdjust = state.attitudeAdjust
  
  case dPadInputType 
  of Constant:
    state.setAttitudeAdjust(direction)
  of Linear, Parabolic, Sinical, EaseOutBack:
    if direction == 0.0: # reset immediately
      state.attitudeAdjust = none(AttitudeAdjust)
    elif optAdjust.isNone or optAdjust.get.direction != direction: # initial application
      state.setAttitudeAdjust(direction)
  of Jolt:
    if state.attitudeAdjust.isNone: # this type can only be applied once the previous jolt has been reset
      state.setAttitudeAdjust(direction)

  # if not currently flipping, set rider animation
  # this check is done to prevent clashing animations
  if state.finishFlipDirectionAt.isNone:
    state.setRiderAttitudeAdjustPosition(
      direction * state.driveDirection,
    )

proc applyButtonAttitudeAdjust(state: GameState) {.raises: [].} =
  let optAdjust = state.attitudeAdjust
  if optAdjust.isNone:
    return
  let adjust = optAdjust.get

  let direction = adjust.direction
  let response = attitudeInputResponse((state.time - adjust.startedAt).toSeconds())
  let torque = direction * response
  if abs(torque) < minAttitudeAdjustForce:
    return # todo remove adjust? note this would cancel jolt
  state.lastTorque = torque
  state.chassis.torque = torque

proc applyAccelerometerAttitudeAdjust(state: GameState) {.raises: [].} =
  let torque = 30_000.0 * getAccelerometerX()
  state.lastTorque = torque
  state.chassis.torque = torque

proc updateAttitudeAdjust*(state: GameState) {.raises: [].} =
    if state.gameResult.isSome:
      return

    if state.isAccelerometerEnabled:
      state.applyAccelerometerAttitudeAdjust()
    else:
      state.applyButtonAttitudeAdjust()


proc onFlipDirection(state: GameState) =
  if state.attitudeAdjust.isSome:
    print("attitude adjust in progress, reset attitude adjust force before flipping")
    # reset animation to neutral
    state.resetRiderAttitudePosition()
    state.attitudeAdjust = none(AttitudeAdjust)
  
  state.driveDirection *= -1.0
  state.flipBikeDirection()
  let riderPosition = localToWorld(state.chassis, riderOffset.transform(state.driveDirection))
  state.flipRiderDirection(riderPosition)
  state.finishFlipDirectionAt = some(state.time + 500.Milliseconds)

proc applyConfig*(state: GameState) =
  let config = getConfig()
  dPadInputType = config.getDPadInputType()
  attitudeInputResponse = config.toInputResponse()
  state.isAccelerometerEnabled = config.getTiltAttitudeAdjustEnabled()

proc resetGameInput*(state: GameState) =
  print("resetGameInput")
  state.isThrottlePressed = false
  state.applyConfig()

proc handleInput*(state: GameState) =
  state.isThrottlePressed = false

  let buttonState = playdate.system.getButtonState()

  if not state.isGameStarted and buttonState.pushed.anyButton:
    state.isGameStarted = true

  if state.gameResult.isSome:
    # when the game is over, the bike cannot be controlled anymore,
    # but any button can be pressed to navigate to the result screen
    if kButtonA in buttonState.pushed:
      state.resetGameOnResume = true
      navigateToGameResult(state.gameResult.get)
    return

  if actionThrottle in buttonState.current:
    state.isThrottlePressed = true
    state.onThrottle()
  if actionBrake in buttonState.current:
    state.onBrake()
  
  if state.isAccelerometerEnabled:
    state.setAttitudeAdjust(getAccelerometerX())
  else:
    if actionLeanLeft in buttonState.current:
      state.onButtonAttitudeAdjust(ROT_CCW)
    elif actionLeanRight in buttonState.current:
      state.onButtonAttitudeAdjust(ROT_CW)
    else:
      state.onButtonAttitudeAdjust(0.0)

  if actionFlipDirection in buttonState.pushed:
    print("Flip direction pressed")
    state.onFlipDirection()

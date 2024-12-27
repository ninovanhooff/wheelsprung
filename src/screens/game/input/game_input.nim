{.push raises: [].}
import std/[options, sugar, math]
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
import game_input_recording

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
    state.lastTorque = 0.0
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

    let targetRestAngle = degToRad(-30.0 * state.driveDirection) + state.lastTorque / -20_000f
    state.tailRotarySpring.restAngle= lerp(
      state.tailRotarySpring.restAngle,
      targetRestAngle,
      0.2
    )

proc onFlipDirection(state: GameState) =
  if state.attitudeAdjust.isSome:
    echo("attitude adjust in progress, reset attitude adjust force before flipping")
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
  echo("resetGameInput")
  state.isThrottlePressed = false
  state.applyConfig()

proc isInReplayMode*(state: GameState): bool =
  return state.inputProvider of RecordedInputProvider

proc isInLiveMode*(state: GameState): bool =
  return state.inputProvider of LiveInputProvider

proc handleInput*(state: GameState, liveButtonState: PDButtonState, onShowGameResultPressed: VoidCallback, onRestartGamePressed: VoidCallback ) =
  state.isThrottlePressed = false

  if state.gameResult.isSome:
    # when the game is over, the bike cannot be controlled anymore,
    # but any button can be pressed to navigate to the result screen
    # always take the button state from the system, we don't want this controlled by the recorded input

    let resultType = state.gameResult.get.resultType

    if state.isInLiveMode:
      if kButtonA in liveButtonState.pushed:
        if resultType == GameResultType.GameOver:
          onRestartGamePressed()
        elif resultType == GameResultType.LevelComplete:
          onShowGameResultPressed()
      elif kButtonB in liveButtonState.pushed:
        if resultType == GameResultType.GameOver:
          onShowGameResultPressed()
        elif resultType == GameResultType.LevelComplete:
          onRestartGamePressed()
    return

  if state.isGamePaused:
    return

  let providedButtonState = state.inputProvider.getButtonState(state.frameCounter)

  if not state.isGameStarted and providedButtonState.pushed.anyButton:
    state.isGameStarted = true

  if actionThrottle in providedButtonState.current:
    state.isThrottlePressed = true
    state.onThrottle()
  if actionBrake in providedButtonState.current:
    state.onBrake()
  
  if state.isAccelerometerEnabled:
    state.setAttitudeAdjust(getAccelerometerX())
  else:
    if actionLeanLeft in providedButtonState.current:
      state.onButtonAttitudeAdjust(ROT_CCW)
    elif actionLeanRight in providedButtonState.current:
      state.onButtonAttitudeAdjust(ROT_CW)
    else:
      state.onButtonAttitudeAdjust(0.0)

  if actionFlipDirection in providedButtonState.pushed:
    echo("Flip direction pressed")
    state.onFlipDirection()

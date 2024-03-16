import std/[options, math]
import std/setutils
import playdate/api
import chipmunk7, chipmunk_utils
import utils
import game_types, game_constants
import game_bike, game_rider
import shared_types
import configuration
import screens/dialog/dialog_screen

const
  crankDeadZone = 5.0f
  maxWheelAngularVelocity = 30.0
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

  initialAttitudeAdjustTorque = 90_000.0
  crankMaxAttitudeAdjustForce = 30_000.0

# simulator overrides
if defined simulator:
  actionThrottle = kButtonUp
  actionBrake = kButtonDown
  actionFlipDirection = kButtonB

const PITAU = 360f + 180f
proc attitudeAdjustForCrankAngle*(crankAngle, calibrationAngle: float32): float32 =
  ## Convert the crank angle to a value between 
  ## -2 and 2 for [-180 .. +180] degrees from calibrationAngle
  # https://gamedev.stackexchange.com/a/169509
  let adjustDegrees = (( crankAngle - calibrationAngle + PITAU ) mod 360f) - 180f
  return (adjustDegrees / 90f)

proc onThrottle*(state: GameState) =
  let rearWheel = state.rearWheel
  let dd = state.driveDirection
  if rearWheel.angularVelocity * dd > maxWheelAngularVelocity:
    return

  rearWheel.torque = throttleTorque * dd

proc onBrake*(state: GameState) =
  let rearWheel = state.rearWheel
  let frontWheel = state.frontWheel
  rearWheel.torque = -rearWheel.angularVelocity * brakeTorque
  frontWheel.torque = -frontWheel.angularVelocity * brakeTorque

proc onButtonAttitudeAdjust(state: GameState, direction: float) =
  if state.attitudeAdjustForce == 0f:
    state.attitudeAdjustForce = direction * initialAttitudeAdjustTorque

proc onCrankAttitudeAdjust(state: GameState, crankAngle: float32) =
  let adjust = attitudeAdjustForCrankAngle(crankAngle, state.crankNeutralAngle)
  state.attitudeAdjustForce = adjust * crankMaxAttitudeAdjustForce

proc onFlipDirection(state: GameState) =
  state.driveDirection *= -1.0
  state.flipBikeDirection()
  let riderPosition = localToWorld(state.chassis, riderOffset.transform(state.driveDirection))
  state.flipRiderDirection(riderPosition)
  state.finishFlipDirectionAt = some(state.time + 0.5.Seconds)

proc resumeGameInput*(state: GameState) =
  state.isThrottlePressed = false
  initialAttitudeAdjustTorque = 90_000.0 * getDPadInputMultiplier(getConfig())

const allButtons: PDButtons = PDButton.fullSet
proc anyButton(buttons: PDButtons): bool =
  (buttons * allButtons).len > 0

proc handleInput*(state: GameState) =
  state.isThrottlePressed = false

  let buttonsState = playdate.system.getButtonsState()

  if not state.isGameStarted and buttonsState.pushed.anyButton:
    state.isGameStarted = true
    if not playdate.system.isCrankDocked:
      state.crankNeutralAngle = playdate.system.getCrankAngle()

  if state.gameResult.isSome:
    # when the game is over, the bike cannot be controlled anymore,
    # but any button can be pressed to navigate to the result screen
    if buttonsState.pushed.len > 0:
      navigateToGameResult(state.gameResult.get)
    return

  if actionThrottle in buttonsState.current:
    state.isThrottlePressed = true
    state.onThrottle()
  if actionBrake in buttonsState.current:
    state.onBrake()
  
  if actionLeanLeft in buttonsState.current:
    state.onButtonAttitudeAdjust(-1f)
  elif actionLeanRight in buttonsState.current:
    state.onButtonAttitudeAdjust(1f)
  elif not playdate.system.isCrankDocked:
    let angle = playdate.system.getCrankAngle()
    if angle.abs > crankDeadZone:
      state.onCrankAttitudeAdjust(angle)

  if actionFlipDirection in buttonsState.pushed:
    print("Flip direction pressed")
    state.onFlipDirection()


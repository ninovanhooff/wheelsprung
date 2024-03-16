import std/[math, options]
import std/setutils
import playdate/api
import chipmunk7, chipmunk_utils
import utils
import game_types, game_constants
import game_bike, game_rider
import shared_types
import configuration
import configuration_types
import screens/dialog/dialog_screen

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

  # adjust force parameters, set on resume
  initialAttitudeAdjustTorque = 0.0
  attitudeAdjustAmplification = 1.0
  maxAttitudeAdjustForce = 0.0

  dPadInputType: DPadInputType

# simulator overrides
if defined simulator:
  actionThrottle = kButtonUp
  actionBrake = kButtonDown
  actionFlipDirection = kButtonB

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
  ## Called on every frame, direction may be 0.0 if the button is not pressed
  
  case dPadInputType 
  of Constant:
    # apply if not zero, reset immediately if zero
    state.attitudeAdjustForce = direction * initialAttitudeAdjustTorque
  of Gradual:
    if direction == 0.0: # reset immediately
      state.attitudeAdjustForce = 0.0
    elif state.attitudeAdjustForce == 0.0 or state.attitudeAdjustForce.signbit != direction.signbit: # initial application
      state.attitudeAdjustForce = direction * initialAttitudeAdjustTorque
  of Jolt:
    if state.attitudeAdjustForce == 0.0: # this type can only be applied once the previous jolt has been reset
      state.attitudeAdjustForce = direction * initialAttitudeAdjustTorque

proc updateAttitudeAdjust*(state: GameState) =
  let chassis = state.chassis

  if state.attitudeAdjustForce != 0.0:
    if state.gameResult.isSome:
      state.attitudeAdjustForce = 0.0
      return

    chassis.torque = state.attitudeAdjustForce

    case dPadInputType
    of Constant:
      discard # no need to change the force
    of Gradual, Jolt:
      state.attitudeAdjustForce *= attitudeAdjustAmplification

    if state.attitudeAdjustForce.abs < minAttitudeAdjustForce:
      state.attitudeAdjustForce = 0.0

    state.attitudeAdjustForce = clamp(state.attitudeAdjustForce, -maxAttitudeAdjustForce, maxAttitudeAdjustForce)

proc onFlipDirection(state: GameState) =
  state.driveDirection *= -1.0
  state.flipBikeDirection()
  let riderPosition = localToWorld(state.chassis, riderOffset.transform(state.driveDirection))
  state.flipRiderDirection(riderPosition)
  state.finishFlipDirectionAt = some(state.time + 0.5.Seconds)

proc resumeGameInput*(state: GameState) =
  state.isThrottlePressed = false

  let config = getConfig()
  dPadInputType = config.getDPadInputType()

  # Parameters tuned on Desmos: https://www.desmos.com/calculator/rsyi3zaobh

  case dPadInputType
  of Constant:
    initialAttitudeAdjustTorque = 30_000.0 * config.getDPadInputMultiplier()
    attitudeAdjustAmplification = 1.0
    maxAttitudeAdjustForce = initialAttitudeAdjustTorque
  of Gradual:
    initialAttitudeAdjustTorque = 20_000.0 * config.getDPadInputMultiplier()
    attitudeAdjustAmplification = 1.03
    maxAttitudeAdjustForce = 2.0 * initialAttitudeAdjustTorque
  of Jolt:
    initialAttitudeAdjustTorque = 90_000.0 * config.getDPadInputMultiplier()
    attitudeAdjustAmplification = 0.75
    maxAttitudeAdjustForce = initialAttitudeAdjustTorque
  

const allButtons: PDButtons = PDButton.fullSet
proc anyButton(buttons: PDButtons): bool =
  (buttons * allButtons).len > 0

proc handleInput*(state: GameState) =
  state.isThrottlePressed = false

  let buttonsState = playdate.system.getButtonsState()

  if not state.isGameStarted and buttonsState.pushed.anyButton:
    state.isGameStarted = true

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
    state.onButtonAttitudeAdjust(-1.0)
  elif actionLeanRight in buttonsState.current:
    state.onButtonAttitudeAdjust(1.0)
  else:
    state.onButtonAttitudeAdjust(0.0)

  if actionFlipDirection in buttonsState.pushed:
    print("Flip direction pressed")
    state.onFlipDirection()

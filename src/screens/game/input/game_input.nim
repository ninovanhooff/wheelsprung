{.push raises: [].}
import std/[options, sugar, math]
import std/setutils
import playdate/api
import chipmunk7, chipmunk_utils
import utils
import screens/game/[
  game_types, game_constants, game_bike, game_rider
]
import shared_types
import configuration, configuration_types
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

  dPadInputType: DPadInputType
  attitudeInputResponse: (t: Seconds) -> Float

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

proc setAttitudeAdjust(state: GameState, direction: Float) =
  print("setAttitudeAdjust", direction)
  state.attitudeAdjust = some(AttitudeAdjust(
    direction: direction,
    startedAt: state.time
  ))

proc onButtonAttitudeAdjust(state: GameState, direction: Float) =
  ## Called on every frame, direction may be 0.0 if the button is not pressed
  
  if direction == 0.0:
    if state.attitudeAdjust.isSome:
      state.attitudeAdjust = none(AttitudeAdjust)
    return

  let optAdjust = state.attitudeAdjust
  
  case dPadInputType 
  of Constant:
    state.setAttitudeAdjust(direction)
  of Parabolic, Sinical, EaseOutBack:
    if direction == 0.0: # reset immediately
      state.attitudeAdjust = none(AttitudeAdjust)
    elif optAdjust.isNone or optAdjust.get.direction != direction: # initial application
      state.setAttitudeAdjust(direction)
  of Jolt:
    if state.attitudeAdjust.isNone: # this type can only be applied once the previous jolt has been reset
      state.setAttitudeAdjust(direction)

proc applyAttitudeAdjust*(state: GameState) {.raises: [].} =
  let optAdjust = state.attitudeAdjust
  if optAdjust.isNone:
    return
  let adjust = optAdjust.get

  let direction = adjust.direction
  let response = attitudeInputResponse(state.time - adjust.startedAt)
  let torque = direction * response
  if abs(torque) < minAttitudeAdjustForce:
    print("attitude adjust force too low", torque, direction, response)
    return # todo remove adjust? note this would cancel jolt
  print("attitude adjust", torque)
  adjust.lastTorque = torque
  state.chassis.torque = torque

proc updateAttitudeAdjust*(state: GameState) {.raises: [].} =

  if state.attitudeAdjust.isSome:
    if state.gameResult.isSome:
      state.attitudeAdjust = none(AttitudeAdjust)
      return
    
    # apply force
    state.applyAttitudeAdjust()


proc onFlipDirection(state: GameState) =
  state.driveDirection *= -1.0
  state.flipBikeDirection()
  let riderPosition = localToWorld(state.chassis, riderOffset.transform(state.driveDirection))
  state.flipRiderDirection(riderPosition)
  state.finishFlipDirectionAt = some(state.time + 0.5.Seconds)

proc toInputResponse(config: Config): (t: Seconds) -> Float =
  let inputType = config.getDPadInputType()
  let multiplier = config.getDPadInputMultiplier()

  # parameters tuned on Desmos: https://www.desmos.com/calculator/w4zbw0thzd

  case inputType
  of Constant:
    return (t: Seconds) => (30_000.0 * multiplier).Float
  of EaseOutBack: return proc (t: Seconds) : Float =
    result = (multiplier * 20_000.0).Float
    if (t >= 0.7):
      ## constant sustain
      result *= 1.5
    else:
      result *= 1.5 + (5.0 + 3.6) * (t - 0.7) ^ 3 + 5.0 * (t - 0.7) ^ 2
  of Sinical: return proc (t: Seconds) : Float =
    result = (multiplier * 20_000.0).Float
    if (t >= 0.7):
      ## constant sustain
      result *= 1.5
    else:
      result *= 1.5 + 0.5 * sin(6.732 * t - HALF_PI)
  of Parabolic: return proc (t: Seconds) : Float =
    result = (multiplier * 20_000.0).Float
    if (t >= 0.7):
      ## constant sustain
      result *= 1.5
    else:
      ## parabolic increase and decrease
      result *= 2 - (2.44 * t - 1) ^ 2
  of Jolt: return (t: Seconds) => (
    ## Logariithmic decay starting at multiplier * 90_000.0
    ## Periodic with period 0.46 seconds
    let exp: int32 = (physicsTickRate * (t mod 0.46)).int32
    (multiplier * 90_000.0 * (0.75 ^ exp)).Float
  )

proc resumeGameInput*(state: GameState) =
  state.isThrottlePressed = false

  let config = getConfig()
  dPadInputType = config.getDPadInputType()
  attitudeInputResponse = config.toInputResponse()

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

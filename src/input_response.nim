{.push raises: [].}
import std/[sugar, math]
import chipmunk7
import screens/game/game_constants
import shared_types
import configuration, configuration_types

type InputResponse = (Seconds) -> Float

proc toInputResponse*(config: Config): InputResponse =
  let inputType = config.getDPadInputType()
  let multiplier = config.getDPadInputMultiplier()

  # parameters tuned on Desmos: https://www.desmos.com/calculator/w4zbw0thzd

  case inputType
  of Constant:
    return (t: Seconds) => (30_000.0 * multiplier).Float
  of Linear: return proc (t: Seconds) : Float =
    result = (multiplier * 20_000.0).Float
    if (t >= 0.7):
      ## constant sustain
      result *= 1.5
    else:
      result *= 0.7*t + 1.0
  of EaseOutBack: return proc (t: Seconds) : Float =
    result = (multiplier * 20_000.0).Float
    if (t >= 0.7):
      ## constant sustain
      result *= 1.5
    else:
      result *= 1.5 + 8.6 * (t - 0.7) ^ 3 + 5.0 * (t - 0.7) ^ 2
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

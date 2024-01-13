import std/math
import playdate/api

const
  TwoPi*: float = 2 * PI

proc print*(str: auto) =
  playdate.system.logToConsole($str)

proc normalizeAngle*(angle: float): float =
    ## normalize angle to be between 0 and 2 * PI
    result = angle mod TwoPi
    if result < 0:
        result += TwoPi


proc roundToNearest*(num: float, increment: int = 1): int =
    ## round to the nearest multiple of increment
    ## ie to nearest 2: 1 -> 0, 2.1 -> 2, 2.6 -> 2, 3.1 -> 4, -1.1 -> -2

    math.floor(num / increment.float + 0.5).int * increment

proc lerp*(initial: float, target: float, factor: float): float =
    result = (initial * (1.0 - factor)) + (target * factor)

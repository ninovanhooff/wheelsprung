import std/math
import playdate/api

const
  TwoPi*: float32 = 2 * PI

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

# todo move to unit tests
assert normalizeAngle(0) == 0
assert normalizeAngle(PI) == PI
assert normalizeAngle(2 * PI) == 0
assert normalizeAngle(3 * PI) == PI
assert normalizeAngle(-PI) == PI
assert normalizeAngle(-2 * PI) == 0
assert normalizeAngle(-3 * PI) == PI

assert roundToNearest(1305, 100) == 1300
assert roundToNearest(1351, 100) == 1400

assert lerp(0, 10, 0) == 0
assert lerp(0, 10, 1) == 10
assert lerp(0, 10, 0.5) == 5
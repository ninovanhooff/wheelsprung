import std/math
import playdate/api

proc print*(str: auto) =
  playdate.system.logToConsole($str)


proc roundToNearest*(num: float, increment: int = 1): int =
    ## round to the nearest multiple of increment
    ## ie to nearest 2: 1 -> 0, 2.1 -> 2, 2.6 -> 2, 3.1 -> 4, -1.1 -> -2

    math.floor(num / increment.float + 0.5).int * increment

proc lerp*(initial: float, target: float, factor: float): float =
    result = (initial * (1.0 - factor)) + (target * factor)

# todo move to unit tests
assert roundToNearest(1305, 100) == 1300
assert roundToNearest(1351, 100) == 1400

assert lerp(0, 10, 0) == 0
assert lerp(0, 10, 1) == 10
assert lerp(0, 10, 0.5) == 5
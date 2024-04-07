import std/math
import std/strutils
import playdate/api

const
  Pi32*: float32 = PI
  TwoPi*: float32 = 2 * PI

### Time
proc now*(): uint = playdate.system.getCurrentTimeMilliseconds

### Logging
proc print*(things: varargs[string, `$`]) =
  ## Print any type by calling $ on it to convert it to string
  playdate.system.logToConsole($now() & ": " &  things.join("\t"))

## Text
proc vertical*(text: string): string =
  ## Convert text to vertical text
  result = ""
  for i in 0..<text.len:
    result.add(text[i])
    result.add("\n")

### Enums
proc nextWrapped*[T: enum](v: T): T =
  if v == high(T):
    return low(T)
  else:
    return succ(v)

proc prevWrapped*[T: enum](v: T): T =
  if v == low(T):
    return high(T)
  else:
    return pred(v)

### Math
proc normalizeAngle*(angle: float32): float32 {.inline.} =
    ## normalize angle to be between 0 (inclusive) and 2 * PI (exclusive)
    result = angle mod TwoPi
    if result < 0.0f:
        result += TwoPi
    # In case angle was very close to TwoPi or 0.0, the result may be equal to TwoPi.
    # Therefore, we use if instead of elif
    if result >= TwoPi:
        result -= TwoPi

proc roundToNearest*(num: float, increment: int = 1): int =
    ## round to the nearest multiple of increment
    ## ie to nearest 2: 1 -> 0, 2.1 -> 2, 2.6 -> 2, 3.1 -> 4, -1.1 -> -2

    math.floor(num / increment.float + 0.5).int * increment

proc lerp*(initial, target, factor: not float32): float64 =
  ## linear interpolation between initial and target
  ## factor is a value between 0.0 and 1.0
  ## the result is clamped between initial and target
  result = (initial * (1.0 - factor)) + (target * factor)
  result = min(max(result, initial), target)

proc lerp*(initial, target, factor: float32): float32 =
  ## linear interpolation between initial and target
  ## factor is a value between 0.0 and 1.0
  ## the result is clamped between initial and target
  result = (initial * (1.0f - factor)) + (target * factor)
  result = min(max(result, initial), target)

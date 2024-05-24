import std/[math, options]
import std/[strutils, setutils]
import std/tables
import playdate/api
import common/shared_types

const
  Pi32*: float32 = PI
  TwoPi*: float32 = 2 * PI

### Time
proc currentTimeMilliseconds*(): int32 {.inline.} = playdate.system.getCurrentTimeMilliseconds.int32
proc currentTimeSeconds*(): Seconds {.inline.} = (currentTimeMilliseconds() / 1000).Seconds

proc formatTime*(time: Seconds): string =
  ## Format time in seconds to a string in the format "MM:SS.ff"
  return formatTime(time * 1000)

proc formatTime*(time: Milliseconds, signed: bool = false): string =
  ## Format time in seconds to a string in the format "MM:SS.ff"
  
  let absTime = abs(time)
  let minutes = absTime div 360_000
  let seconds = absTime mod 60_000 div 1000
  let hundredths = absTime mod 1000 div 10
  let signString = 
    if signed and time < 0: "-" 
    elif signed and time >= 0: "+" 
    else: ""
  return fmt"{signString}{minutes:02}:{seconds:02}.{hundredths:02}"


proc expire*(expireAt: var Option[Milliseconds], currentTime: Milliseconds): bool =
  ## Sets expireAt to none and returns true if expireAt is after currentTime
  if expireAt.isSome:
    if currentTime > expireAt.get:
      expireAt = none[Milliseconds]()
      return true
  return false

### Logging
proc print*(things: varargs[string, `$`]) =
  ## Print any type by calling $ on it to convert it to string
  playdate.system.logToConsole($currentTimeMilliseconds() & ": " &  things.join("\t"))

### Bench / trace / profile


proc bench*(toTest: proc() {.raises:[].}, name: string = "", numSamples: int32 = 1) =
  ## Measure the time taken by a procedure
  let startTime = playdate.system.getElapsedTime
  toTest()
  let endTime = playdate.system.getElapsedTime
  print(name, "took", (endTime - startTime) * 0.001f, "ms")

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

proc roundToNearestInt*(num: float32, increment: int32 = 1): int32 =
  ## round to the nearest multiple of increment
  ## ie to nearest 2: 1 -> 0, 2.1 -> 2, 2.6 -> 2, 3.1 -> 4, -1.1 -> -2

  math.floor(num / increment.float32 + 0.5f).int32 * increment

proc lerp*(initial, target, factor: not float32): float64 =
  ## linear interpolation between initial and target
  ## factor is a value between 0.0 and 1.0
  ## the result is clamped between initial and target
  result = initial + (target - initial) * clamp(factor, 0.0, 1.0)

proc lerp*(initial, target, factor: float32): float32 =
  ## linear interpolation between initial and target
  ## factor is a value between 0.0 and 1.0
  ## the result is clamped between initial and target
  # if target < initial:
  #   (initial, target) = (target, initial)
  # result = (initial * (1.0f - factor)) + (target * factor)
  # result = min(max(result, initial), target)
  result = initial + (target - initial) * clamp(factor, 0f, 1f)

### Sequences

proc findFirst*[T](s: seq[T], pred: proc(x: T): bool): Option[T] =
  ## find the first item in the sequence that satisfies the predicate
  result = none(T)  # return none if no item satisfies the predicate
  for i, x in s:
    if pred(x):
      result = some[T](x)
      break

proc findFirstIndexed*[T](s: seq[T], pred: proc(x: T): bool): (int, Option[T]) =
  ## find the first item in the sequence that satisfies the predicate
  result = (-1, none(T))  # return none if no item satisfies the predicate
  for i, x in s:
    if pred(x):
      result = (i, some[T](x))
      break

### input

const allButtons: PDButtons = PDButton.fullSet
proc anyButton*(buttons: PDButtons): bool =
  (buttons * allButtons).len > 0

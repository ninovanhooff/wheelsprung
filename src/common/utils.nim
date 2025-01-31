import std/[math, options]
import std/[strutils, setutils]
import std/tables
import playdate/api
import common/shared_types

const
  Pi32*: float32 = PI
  TwoPi*: float32 = 2 * PI
  NOMINAL_FRAME_RATE*: float32 = 50.0f
  NOMINAL_FRAME_TIME_MILLIS*: uint32 = (1000.0f / NOMINAL_FRAME_RATE).uint32

### Time
proc currentTimeMilliseconds*(): int32 {.inline.} = playdate.system.getCurrentTimeMilliseconds.int32
proc currentTimeSeconds*(): Seconds {.inline.} = (currentTimeMilliseconds() / 1000).Seconds
proc getElapsedSeconds*(): Seconds {.inline.} = playdate.system.getElapsedTime.Seconds

proc formatTime*(time: Seconds): string =
  ## Format time in seconds to a string in the format "MM:SS.ff"
  return formatTime(time * 1000)

proc formatTime*(time: Milliseconds, signed: bool = false, trim: bool = false): string =
  ## Format time in miliseconds to a string in the format "MM:SS.ff"
  ## If signed is true, the string will include a sign (+ or -) for negative times
  ## If trim is true, the string will not include minutes if the time is less than 1 minute
  
  let absTime = abs(time)
  let minutes = absTime div 60_000
  let seconds = absTime mod 60_000 div 1000
  let hundredths = absTime mod 1000 div 10
  let signString = 
    if signed and time < 0: "-" 
    elif signed and time >= 0: "+" 
    else: ""
  if trim and minutes == 0:
    return fmt"{signString}{seconds}.{hundredths:02}"
  else:
    return fmt"{signString}{minutes:02}:{seconds:02}.{hundredths:02}"


proc expire*[T](expireAt: var Option[T], currentTime: T): bool {.discardable} =
  ## Sets expireAt to none and returns true if expireAt is after currentTime
  if expireAt.isSome:
    if currentTime > expireAt.get:
      expireAt = none[T]()
      return true
  return false

### Logging
var printTStartTime: Seconds = -1f

proc print*(things: varargs[string, `$`]) =
  ## Print any type by calling $ on it to convert it to string
  playdate.system.logToConsole($currentTimeMilliseconds() & ": " &  things.join("\t"))

proc printException*(message: string, e: ref Exception) =
  ## Print an exception
  let message = fmt"{message}:{getCurrentExceptionMsg()}\n{e.getStackTrace()}"
  # Log the error to the console, total stack trace might be too long for single call
  for line in message.splitLines():
    playdate.system.logToConsole(line)

proc printT*(things: varargs[string, `$`]) =
  let duration = playdate.system.getElapsedTime - printTStartTime
  printTStartTime = -1f
  # if defined(device):
    # timing info is only meaningful on device
  playdate.system.logToConsole($currentTimeMilliseconds() & ": " &  things.join("\t") & " in ms:" & $(duration * 1000f))

proc markStartTime*() =
  ## Mark the start time for the printT function
  printTStartTime = playdate.system.getElapsedTime

### Bench / trace / profile

var benchTable: Table[string, seq[float32]] = initTable[string, seq[float32]]()

proc addBenchSample(samples: var seq[float32], sample: float32, name: string, numSamples: int32): bool =
  samples.add(sample)
  if samples.len < numSamples:
    return false

  # calculate mean, min and max
  var min = float32.high
  var max = 0f
  var mean = 0f
  for s in samples:
    if s < min:
      min = s
    if s > max:
      max = s
    mean += s
  mean /= samples.len.float32
  print(name,"Mean:", mean * 1000, "Min:", min * 1000, "Max:", max * 1000, "ms")    
  return true    


proc bench*(toTest: proc() {.raises:[].}, name: string = "", numSamples: int32 = 1) {.raises:[].} =
  ## Measure the time taken by a procedure
  let startTime = playdate.system.getElapsedTime
  toTest()
  let endTime = playdate.system.getElapsedTime
  if name == "" or numSamples == 1:
    print(name, "took", (endTime - startTime) * 0.001f, "ms")
  elif benchTable.mgetOrPut(name, @[]).addBenchSample((endTime - startTime), name, numSamples):
    benchTable.del name

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

proc rem*(n: int, m: int): int =
  ## remainder function that always returns a positive result
  ((n mod m) + m) mod m

### Sequences

proc findFirst*[T](s: seq[T], pred: proc(x: T): bool): Option[T] {.raises: [], effectsOf: pred.} =
  ## find the first item in the sequence that satisfies the predicate
  result = none(T)  # return none if no item satisfies the predicate
  for i, x in s:
    if pred(x):
      result = some[T](x)
      break

proc findFirstIndexed*[T](s: seq[T], pred: proc(x: T): bool): (int, Option[T]) {.raises: [], effectsOf: pred.} =
  ## find the first item in the sequence that satisfies the predicate
  ## returns the index and the item
  ## returns (-1, none) if no item satisfies the predicate
  result = (-1, none(T))  # return none if no item satisfies the predicate
  for i, x in s:
    if pred(x):
      result = (i, some[T](x))
      break

### input

const allButtons: PDButtons = PDButton.fullSet
proc anyButton*(buttons: PDButtons): bool =
  (buttons * allButtons).len > 0

proc anyButton*(a: PDButtons, b: PDButtons): bool =
  return (a * b).len > 0

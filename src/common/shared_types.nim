import chipmunk7
import std/options
import input/input_types

type
  Seconds* = Float
  Milliseconds* = int32

  Path* = string

  DPadInputType* {.pure.} = enum
    Constant, Linear, Parabolic, Sinical, EaseOutBack, Jolt

  GameResultType* {.pure.} = enum
    ## Keep in order bad to good, used to rank the results.
    GameOver, LevelComplete

  LevelProgress* = ref object of RootObj
    levelId*: Path
    bestTime*: Option[Milliseconds]
    hasCollectedStar*: bool
    signature*: Option[string]

  GameResult* = ref object of RootObj
    levelId*: Path
    levelHash*: string
    resultType*: GameResultType
    time*: Milliseconds
    starCollected*: bool
    hintsAvailable*: bool
    inputRecording*: Option[InputRecording]

  VoidCallback* = proc() {.raises:[].}

let fallbackGameResult*: GameResult = GameResult(
  resultType: GameResultType.low,
  time: Milliseconds.high, # use the worst possible time, so that when comparing, it will be the worst
  starCollected: false
)

let noOp*: VoidCallback = proc() {.raises: [].} =
  ## A no-op function that does nothing.
  ## It can be used as a placeholder or a default callback function.
  discard

proc toSeconds*(milliseconds: Milliseconds): Seconds {.inline.} =
  ## Converts milliseconds to seconds.
  result = float32(milliseconds) / 1000

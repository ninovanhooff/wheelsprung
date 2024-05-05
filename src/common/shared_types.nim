import chipmunk7

type
  Seconds* = Float
  Milliseconds* = int32

  Path* = string

  DPadInputType* {.pure.} = enum
    Constant, Linear, Parabolic, Sinical, EaseOutBack, Jolt

  GameResultType* {.pure.} = enum
    GameOver, LevelComplete

  GameResult* = ref object of RootObj
    levelId*: Path
    resultType*: GameResultType
    time*: Milliseconds
    starCollected*: bool

  VoidCallBack* = proc() {.raises:[].}

proc toSeconds*(milliseconds: Milliseconds): Seconds {.inline.} =
  ## Converts milliseconds to seconds.
  result = float32(milliseconds) / 1000

let noOp*: VoidCallBack = proc() {.raises: [].} =
  ## A no-op function that does nothing.
  ## It can be used as a placeholder or a default callback function.
  discard

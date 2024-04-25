import chipmunk7

type
  Seconds* = Float

  DPadInputType* {.pure.} = enum
    Constant, Linear, Parabolic, Sinical, EaseOutBack, Jolt

  GameResultType* {.pure.} = enum
    GameOver, LevelComplete

  GameResult* = ref object of RootObj
    resultType*: GameResultType
    time*: Seconds
    starCollected*: bool

  VoidCallBack* = proc() {.raises:[].}

let noOp*: VoidCallBack = proc() {.raises: [].} =
  ## A no-op function that does nothing.
  ## It can be used as a placeholder or a default callback function.
  discard

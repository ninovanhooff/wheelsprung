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

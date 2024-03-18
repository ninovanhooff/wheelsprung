import chipmunk7

type
  Seconds* = Float

  DPadInputType* {.pure.} = enum
    Jolt, Constant, Parabolic, Sinical, EaseOutBack

  GameResultType* {.pure.} = enum
    GameOver, LevelComplete

  GameResult* = ref object of RootObj
    resultType*: GameResultType
    time*: Seconds

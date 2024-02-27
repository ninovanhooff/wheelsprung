import chipmunk7

type
  Seconds* = Float

  GameResultType* {.pure.} = enum
    GameOver, LevelComplete

  GameResult* = ref object of RootObj
    resultType*: GameResultType
    time*: Seconds

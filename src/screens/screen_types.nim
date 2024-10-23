type
  ScreenType* {.pure.}= enum
    LevelSelect
    Game
    HitStop
    GameResult
    Settings
  ScreenRestoreState* = object of RootObj
    case screenType*: ScreenType
    of Game:
      levelPath*: string
    of LevelSelect, HitStop, GameResult, Settings:
      discard
  Screen* {.requiresInit.} = ref object of RootObj
    screenType*: ScreenType

type 
  ScreenResult* = ref object
    case screenType*: ScreenType
    of Game: 
      enableHints*: bool
    of LevelSelect, HitStop, GameResult, Settings: 
      discard # no properties

type GameScreen* = ref object of Screen
  isInitialized*: bool
  levelPath*: string

proc newGameScreen*(levelPath:string): GameScreen {.raises:[].} =
  return GameScreen(
    isInitialized: false,
    levelPath: levelPath,
    screenType: ScreenType.Game
  )
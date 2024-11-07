import std/options

type
  ScreenType* {.pure.}= enum
    LevelSelect
    Game
    HitStop
    GameResult
    Leaderboards
    Settings
  ScreenRestoreState* = object of RootObj
    case screenType*: ScreenType
    of Game:
      levelPath*: string
    of Leaderboards:
      currentLeaderboardIdx*: int
    of LevelSelect:
      selectedPath*: Option[string] # cannot use levelPath because it is already defined in Game
    of HitStop, GameResult, Settings:
      discard
  Screen* {.requiresInit.} = ref object of RootObj
    screenType*: ScreenType

type 
  ScreenResult* = ref object
    ## Result container that can be given to screens to indicate some other screen returned a result.
    ## ScreenResult.Gamee will be given to the GameScreen.
    case screenType*: ScreenType
    of Game: 
      enableHints*: bool
    of LevelSelect:
      selectPath*: string
    of HitStop, GameResult, Leaderboards, Settings: 
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
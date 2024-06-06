import navigation/screen

type GameScreen* = ref object of Screen
  isInitialized*: bool
  levelPath*: string

proc newGameScreen*(levelPath:string): GameScreen {.raises:[].} =
  return GameScreen(
    isInitialized: false,
    levelPath: levelPath,
    screenType: ScreenType.Game
  )
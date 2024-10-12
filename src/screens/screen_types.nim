{.push raises: [], warning[LockLevel]:off.}

type 
  ScreenType* {.pure.}= enum
    CutScene
    LevelSelect
    Game
    HitStop
    GameResult
    Settings
    # when adding a new screen, consider whether you should import it in wheelsprung.nim
    # this is the case when "updat not implemented for screen <YourScreen>" is printed in the console
  Screen* {.requiresInit.} = ref object of RootObj
    screenType*: ScreenType

type 
  GameScreen* = ref object of Screen
    isInitialized*: bool
    levelPath*: string
  CutSceneScreen* = ref object of Screen
    isInitialized*: bool

proc newGameScreen*(levelPath:string): GameScreen =
  return GameScreen(
    isInitialized: false,
    levelPath: levelPath,
    screenType: ScreenType.Game
  )

proc newCutSceneScreen*(): CutSceneScreen =
  return CutSceneScreen(screenType: ScreenType.CutScene)

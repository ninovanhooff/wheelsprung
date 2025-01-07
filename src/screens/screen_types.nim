import std/options
import input/input_types
import screens/game/game_types
import screens/cutscene/cutscene_types

type
  ScreenType* {.pure.}= enum
    CutScene
    LevelSelect
    Game
    HitStop
    GameResult
    Leaderboards
    Settings
    # when adding a new screen, consider whether you should import it in wheelsprung.nim
    # this is the case when "updat not implemented for screen <YourScreen>" is printed in the console
  ScreenRestoreState* = object of RootObj
    case screenType*: ScreenType
    of Game:
      levelPath*: string
    of Leaderboards:
      currentLeaderboardIdx*: int
    of LevelSelect:
      selectedPath*: Option[string] # cannot use levelPath because it is already defined in Game
    of CutScene, HitStop, GameResult, Settings:
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
      restartGame*: bool
    of LevelSelect:
      selectPath*: string
    of CutScene, HitStop, GameResult, Leaderboards, Settings:
      discard # no properties

type
  GameScreen* = ref object of Screen
    levelPath*: string
    replayInputRecording*: Option[InputRecording]
    state*: GameState
  CutSceneScreen* = ref object of Screen # todo must this be defined here?
    isInitialized*: bool
    cutsceneId*: CutsceneId


proc newGameScreen*(levelPath:string, recording: Option[InputRecording] = none(InputRecording)): GameScreen =
  return GameScreen(
    levelPath: levelPath,
    replayInputRecording: recording,
    state: nil, # will be initialized in the game screen
    screenType: ScreenType.Game
  )

proc newCutSceneScreen*(): CutSceneScreen =
  return CutSceneScreen(
    screenType: ScreenType.CutScene,
    cutsceneId: CutsceneId.Intro,
  )

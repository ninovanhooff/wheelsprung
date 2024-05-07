## Ported from https://github.com/ninovanhooff/playdate-navigator/blob/a33c2b724dfe7f83d7c406eed3d3aabbb8b550c2/Screen.lua
{.push base, raises: [].}
import common/utils

type 
  ScreenType* {.pure.}= enum
    LevelSelect
    Game
    HitStop
    GameResult
    Settings
  Screen* {.requiresInit.} = ref object of RootObj
    screenType*: ScreenType

method `$`*(self: Screen): string = $self.screenType

method pause*(screen: Screen) =
  discard

method resume*(screen: Screen) =
  ## Notify screen that it will become visible to the user,
  ## either for the first time or after it was paused
  ## and subsequently brought back to the front of the backstack
  ## This is a good place to add system menu items for this screen.
  ## For one-time initialization, use init()
  ## Called before update()
  discard

method destroy*(screen: Screen) =
  discard

method update*(self: Screen): int =
  ##[ returns 0 if no screen update is needed or 1 if there is.
  ]##
  print "update not implemented for screen: " & $self
  return 0

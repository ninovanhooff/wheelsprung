## Ported from https://github.com/ninovanhooff/playdate-navigator/blob/a33c2b724dfe7f83d7c406eed3d3aabbb8b550c2/Screen.lua
{.push base, raises: [].}
import std/options
import common/utils
import cache/bitmap_cache
import screens/screen_types
export screen_types


method `$`*(self: Screen): string = $self.screenType

method pause*(screen: Screen) =
  discard

method resume*(screen: Screen): bool =
  ## Notify screen that it will become visible to the user,
  ## either for the first time or after it was paused
  ## and subsequently brought back to the front of the backstack
  ## This is a good place to add system menu items for this screen.
  ## Called before update()
  ##
  print "resume not implemented for screen: " & $screen & "\nDid you specify the the correct return type (bool)?Did you import this screen from the call site?\nReturning false"

method destroy*(screen: Screen) =
  discard

method update*(screen: Screen): int =
  ##[ returns 0 if no screen update is needed or 1 if there is.
  ]##

  ## Ig you see this message, you may need to import your screen in wheelsprung.nim :-(
  print "update not implemented for screen: " & $screen
  return 0

method setResult*(self: Screen, result: ScreenResult) =
  ## Another screen has finished and returned a result for this screen
  print "ERROR: setResult not implemented for screen: " & $self

method getRestoreState*(self: Screen): Option[ScreenRestoreState] =
  ## Necessary info to restore state after the game is restarted
  print "getRestoreState not implemented for screen: " & $self
  return none(ScreenRestoreState)

method getSystemMenuBitmapId*(self: Screen): BitmapId =
  ## The BitmapId to use for the system menu background when this screen is showing
  BitmapId.QrLevelEditor # default to the QR code bitmap

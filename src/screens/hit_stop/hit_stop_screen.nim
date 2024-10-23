{. push warning[LockLevel]:off.}
import std/options
import random
import playdate/api
import chipmunk7
import navigation/[screen, navigator]
import common/shared_types
import common/utils


## A Screen that Blinks the screen for a few frames

type
  MenuItemDefinition* = ref object of RootObj 
    name*: string
    action*: proc() {.raises: [].}
  MenuItemDefinitions* = seq[MenuItemDefinition]
  HitStopScreen* = ref object of Screen
    currentBitmap: LCDBitmap
    otherBitmap: LCDBitmap
    flipBitmapsAt: Seconds
    menuItems*: MenuItemDefinitions
    onCanceled*: VoidCallBack
    finishAt: Seconds
    maxShakeMagnitude: Float

proc newHitStopScreen*(
  bitmapA: LCDBitmap,
  bitmapB: LCDBitmap,
  maxShakeMagnitude: Float = 10.0f,
  menuItems: MenuItemDefinitions = @[],
  onCanceled: VoidCallBack = noOp,
  duration: Seconds = 0.38.Seconds
): HitStopScreen =
  result = HitStopScreen(currentBitmap: bitmapA, otherBitmap: bitmapB, menuItems: menuItems,
    finishAt: currentTimeSeconds() + duration,
    screenType: ScreenType.HitStop,
    maxShakeMagnitude: duration * maxShakeMagnitude, # normalize to duration
  )

proc createMenuCallback(menuItem: MenuItemDefinition): proc(button: PDMenuItemButton) {.raises: [].} =
  return proc(button: PDMenuItemButton) {.raises:[].}=
    popScreen() # pop self (HitStopScreen)
    menuItem.action()

method resume*(screen: HitStopScreen) =
  for menuItem in screen.menuItems:
    discard playdate.system.addMenuItem(
      menuItem.name, 
      createMenuCallback(menuItem)
    )

method update*(screen: HitStopScreen): int =
  let buttonState = playdate.system.getButtonState()

  if kButtonA in buttonState.pushed:
    popScreen()
    screen.onCanceled()
    return 0
  
  let remainingSeconds = screen.finishAt - currentTimeSeconds()
  if remainingSeconds <= 0.Seconds :
    popScreen()
  elif currentTimeSeconds() > screen.flipBitmapsAt:
    swap(screen.currentBitmap, screen.otherBitmap)
    screen.currentBitmap.draw(0,0, kBitmapUnflipped)
    screen.flipBitmapsAt = currentTimeSeconds() + 0.06.Seconds
  
  # Screen shake
  # Background color is set at program init, in wheelsprung.nim
  let magnitude = (remainingSeconds * screen.maxShakeMagnitude).abs
  playdate.display.setOffset(
    rand(-magnitude .. magnitude).int32,
    rand(-magnitude .. magnitude).int32,
  )

  return 1

method getRestoreState*(self: Screen): Option[ScreenRestoreState] =
  # not worth the effort restoring this screen
  return none(ScreenRestoreState)

{. push warning[LockLevel]:off.}

import random
import playdate/api
import chipmunk7
import navigation/[screen, navigator]
import shared_types
import utils


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
    finishAt: Seconds
    maxShakeMagnitude: Float

proc newHitStopScreen*(
  bitmapA: LCDBitmap,
  bitmapB: LCDBitmap,
  maxShakeMagnitude: Float = 10.0f,
  menuItems: MenuItemDefinitions = @[],
  duration: Seconds = 0.38.Seconds
): HitStopScreen =
  result = HitStopScreen(currentBitmap: bitmapA, otherBitmap: bitmapB, menuItems: menuItems,
    finishAt: currentTimeSeconds() + duration,
    screenType: ScreenType.HitStop,
    maxShakeMagnitude: duration * maxShakeMagnitude, # normalize to duration
  )

proc createMenuCallback(menuItem: MenuItemDefinition): proc(button: PDMenuItemButton) {.raises: [].} =
  print "createMenuCallback", menuItem.name
  return proc(button: PDMenuItemButton) {.raises:[].}=
    popScreen() # pop self (HitStopScreen)
    print "executing menu callback for", menuItem.name
    menuItem.action()

method resume*(screen: HitStopScreen) =
  for menuItem in screen.menuItems:
    discard playdate.system.addMenuItem(
      menuItem.name, 
      createMenuCallback(menuItem)
    )

method update*(screen: HitStopScreen): int =
  let remainingSeconds = screen.finishAt - currentTimeSeconds()
  if remainingSeconds <= 0.Seconds :
    print "HitStopScreen finished", currentTimeSeconds(), screen.finishAt
    popScreen()
  elif currentTimeSeconds() > screen.flipBitmapsAt:
    swap(screen.currentBitmap, screen.otherBitmap)
    screen.currentBitmap.draw(0,0, kBitmapUnflipped)
    screen.flipBitmapsAt = currentTimeSeconds() + 0.06.Seconds
  
  # Screen shake
  # Background color is set at program init, in wheelsprung.nim
  let magnitude = (remainingSeconds * screen.maxShakeMagnitude).int32
  playdate.display.setOffset(
    rand(-magnitude .. magnitude),
    rand(-magnitude .. magnitude),
  )

  return 1

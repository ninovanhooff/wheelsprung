{. push warning[LockLevel]:off.}

import playdate/api
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


proc newHitStopScreen*(
  bitmapA: LCDBitmap,
  bitmapB: LCDBitmap,
  menuItems: MenuItemDefinitions = @[],
  duration: Seconds = 0.5.Seconds
): HitStopScreen =
  result = HitStopScreen(currentBitmap: bitmapA, otherBitmap: bitmapB, menuItems: menuItems,
    finishAt: currentTimeSeconds() + duration,
    screenType: ScreenType.HitStop
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
  if currentTimeSeconds() > screen.finishAt:
    print "HitStopScreen finished", currentTimeSeconds(), screen.finishAt
    popScreen()
  elif currentTimeSeconds() > screen.flipBitmapsAt:
    swap(screen.currentBitmap, screen.otherBitmap)
    screen.currentBitmap.draw(0,0, kBitmapUnflipped)
    screen.flipBitmapsAt = currentTimeSeconds() + 0.1.Seconds
  return 1

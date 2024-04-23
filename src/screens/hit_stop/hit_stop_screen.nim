{. push warning[LockLevel]:off.}

import playdate/api
import navigation/[screen, navigator]
import graphics_types
import shared_types
import utils

import screens/settings/settings_screen


## A Screen that Blinks the screen for a few frames

type
  MenuItemDefinition = tuple[name: string, action: proc() {.raises: [].}]
  MenuItemDefinitions = seq[MenuItemDefinition]
  HitStopScreen* = ref object of Screen
    currentBitmap: LCDBitmap
    otherBitmap: LCDBitmap
    flipBitmapsAt: Seconds
    menuItems: MenuItemDefinitions
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

method resume*(screen: HitStopScreen) =
  for menuItem in screen.menuItems:
    let action = menuItem.action
    let outerCallback = proc() =
      popScreen() # pop self
      action()
    discard playdate.system.addMenuItem(menuItem.name, proc(button: PDMenuItemButton) {.raises: [].} =
      outerCallback()
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

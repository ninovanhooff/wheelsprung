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
    position: Vertex
    bitmap: LCDBitmap
    menuItems: MenuItemDefinitions
    finishAt: Seconds


proc newHitStopScreen*(
  position: Vertex,
  bitmap: LCDBitmap,
  menuItems: MenuItemDefinitions = @[],
  duration: Seconds = 0.5.Seconds
): HitStopScreen =
  result = HitStopScreen(position: position, bitmap: bitmap, menuItems: menuItems,
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
  return 1

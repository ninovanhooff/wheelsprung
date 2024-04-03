import playdate/api
import navigation/[screen, navigator]
import graphics_types
import utils
import configuration

import screens/game/game_screen
import screens/settings/settings_screen

const 
  borderInset = 24
  levelsBasePath = "levels/"
  maxLines = 8 

type LevelSelectScreen = ref object of Screen
  levelPaths: seq[string]
  selectedIndex: int
  scrollPosition: int

proc getLevelPaths(): seq[string] =
  playdate.file.listFiles(levelsBasePath)

proc newLevelSelectScreen*(): LevelSelectScreen =
  return LevelSelectScreen(screenType: ScreenType.LevelSelect)

proc updateScrollPosition(screen: LevelSelectScreen) =
  if screen.selectedIndex < screen.scrollPosition:
    screen.scrollPosition = screen.selectedIndex
  elif screen.selectedIndex > screen.scrollPosition + maxLines - 1:
    screen.scrollPosition = screen.selectedIndex - maxLines + 1

proc updateInput(screen: LevelSelectScreen) =
  let buttonState = playdate.system.getButtonState()

  if kButtonA in buttonState.pushed:
    let levelPath = levelsBasePath & screen.levelPaths[screen.selectedIndex]
    let gameScreen = newGameScreen(levelPath)
    # the ganme screen loaded successfully, save as last opened level
    setLastOpenedLevel(levelPath)
    pushScreen(gameScreen)
  elif kButtonUp in buttonState.pushed:
    screen.selectedIndex -= 1
    if screen.selectedIndex < 0:
      screen.selectedIndex = screen.levelPaths.len - 1
  elif kButtonDown in buttonState.pushed:
    screen.selectedIndex += 1
    if screen.selectedIndex >= screen.levelPaths.len:
      screen.selectedIndex = 0
  elif kButtonDown in buttonState.pushed:
    screen.selectedIndex += 1
    if screen.selectedIndex >= screen.levelPaths.len:
      screen.selectedIndex = 0

  updateScrollPosition(screen)

proc drawBackground() =
  gfx.drawRect(borderInset, borderInset, 400 - 2 * borderInset, 240 - 2 *
      borderInset, kColorBlack)

proc drawTitle(title: string) =
  gfx.drawTextAligned(title, 200, 2)

proc drawLevelPaths(screen: LevelSelectScreen) =
  var y = 40
  let maxIdx = clamp(
    screen.scrollPosition + maxLines - 1, 
    0, screen.levelPaths.high
  )
  for level in screen.levelPaths[screen.scrollPosition .. maxIdx]:
    gfx.drawText(level, borderInset * 2, y)
    y += 20
  let cursorY = 40 + 20 * (screen.selectedIndex - screen.scrollPosition)
  gfx.drawText(">", borderInset + 8, cursorY)

proc drawButtons(screen: LevelSelectScreen) =
  let selectedFileName = screen.levelPaths[screen.selectedIndex]
  gfx.drawTextAligned("Ⓐ Play " & selectedFileName, 200, 218)

proc draw(screen: LevelSelectScreen) =
  gfx.clear(kColorWhite)
  drawBackground()
  drawTitle("Select a level")
  drawLevelPaths(screen)
  drawButtons(screen)

method resume*(screen: LevelSelectScreen) =
  try:
    screen.levelPaths = getLevelPaths()
  except IOError:
    print("Error reading level paths")

  print("paths: ")
  print(screen.levelPaths)

  discard playdate.system.addMenuItem("Settings", proc(menuItem: PDMenuItemButton) =
    pushScreen(newSettingsScreen())
  )

method update*(screen: LevelSelectScreen): int =
  updateInput(screen)
  draw(screen)
  return 1

method `$`*(screen: LevelSelectScreen): string =
  return "LevelSelectScreen"

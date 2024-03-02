import playdate/api
import navigation/[screen, navigator]
import graphics_utils
import utils
import configuration

import screens/game/game_screen

const borderInset = 24
const levelsBasePath = "levels/"

type LevelSelectScreen = ref object of Screen
  levelPaths: seq[string]
  selectedIndex: int

proc getLevelPaths(): seq[string] {.locks:0.} =
  playdate.file.listFiles(levelsBasePath)

proc newLevelSelectScreen*(): LevelSelectScreen =
  return LevelSelectScreen()

proc updateInput(screen: LevelSelectScreen) {.locks:0.} =
  let buttonState = playdate.system.getButtonsState()

  if kButtonA in buttonState.pushed:
    popScreen()
    popScreen()
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

proc drawBackground() =
  gfx.drawRect(borderInset, borderInset, 400 - 2 * borderInset, 240 - 2 * borderInset, kColorBlack)

proc drawTitle(title: string) =
  gfx.drawTextAligned(title, 200, 2)

proc drawLevelPaths(screen: LevelSelectScreen) =
  var y = 40
  for level in screen.levelPaths:
    gfx.drawText(level, borderInset * 2, y)
    y += 20
  
  gfx.drawText(">", borderInset + 8, 40 + screen.selectedIndex * 20)

proc drawButtons(screen: LevelSelectScreen) =
  let selectedFileName = screen.levelPaths[screen.selectedIndex]
  gfx.drawTextAligned("Ⓐ Play " & selectedFileName, 200, 218)

proc draw(screen: LevelSelectScreen) =
  gfx.clear(kColorWhite)
  drawBackground()
  drawTitle("Select a level")
  drawLevelPaths(screen)
  drawButtons(screen)


method resume*(screen: LevelSelectScreen) {.locks:0.} =
  try:
    screen.levelPaths = getLevelPaths()
  except IOError:
    print("Error reading level paths")
    
  print("paths: ")
  print(screen.levelPaths)

method update*(screen: LevelSelectScreen): int {.locks:0.} =
  updateInput(screen)
  draw(screen)
  return 1

method `$`*(screen: LevelSelectScreen): string =
  return "LevelSelectScreen"
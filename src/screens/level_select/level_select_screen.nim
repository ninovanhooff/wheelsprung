import playdate/api
import navigation/[screen, navigator]
import graphics_utils
import utils

import screens/game/game_screen

const borderInset = 16
const levelsBasePath = "levels/"

type LevelSelectScreen = ref object of Screen
  levelPaths: seq[string]
  selectedIndex: int32

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
    pushScreen(newGameScreen(levelPath))

proc drawBackground() =
  gfx.drawRect(borderInset, borderInset, 400 - 2 * borderInset, 240 - 2 * borderInset, kColorBlack)

proc drawTitle(title: string) =
  gfx.drawTextAligned(title, 200, 0)

proc drawLevelPaths(screen: LevelSelectScreen) =
  var y = 40
  for level in screen.levelPaths:
    gfx.drawText(level, borderInset * 2, y)
    y += 20
  
  gfx.drawText(">", borderInset + 8, 40 + screen.selectedIndex * 20)

proc draw(screen: LevelSelectScreen) =
  drawBackground()
  drawTitle("Select a level")
  drawLevelPaths(screen)


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
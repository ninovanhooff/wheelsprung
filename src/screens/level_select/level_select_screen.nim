import playdate/api
import navigation/[screen, navigator]
import common/graphics_types
import common/utils
import configuration/configuration
import level_meta/level_data
import screens/game/game_screen
import screens/settings/settings_screen
import tables

const 
  borderInset = 24
  levelsBasePath = "levels/"
  maxLines = 8 

type LevelSelectScreen = ref object of Screen
  levelMetas: seq[LevelMeta]
  selectedIndex: int
  scrollPosition: int

proc getLevelPaths(): seq[string] =
  playdate.file.listFiles(levelsBasePath)

proc newLevelSelectScreen*(): LevelSelectScreen =
  return LevelSelectScreen(
    levelMetas: @[],
    screenType: ScreenType.LevelSelect
  )

proc updateScrollPosition(screen: LevelSelectScreen) =
  if screen.selectedIndex < screen.scrollPosition:
    screen.scrollPosition = screen.selectedIndex
  elif screen.selectedIndex > screen.scrollPosition + maxLines - 1:
    screen.scrollPosition = screen.selectedIndex - maxLines + 1

proc updateInput(screen: LevelSelectScreen) =
  let buttonState = playdate.system.getButtonState()

  if kButtonA in buttonState.pushed:
    let levelPath = levelsBasePath & screen.levelMetas[screen.selectedIndex].path
    let gameScreen = newGameScreen(levelPath)
    # the ganme screen loaded successfully, save as last opened level
    setLastOpenedLevel(levelPath)
    pushScreen(gameScreen)
  elif kButtonUp in buttonState.pushed:
    screen.selectedIndex -= 1
    if screen.selectedIndex < 0:
      screen.selectedIndex = screen.levelMetas.len - 1
  elif kButtonDown in buttonState.pushed:
    screen.selectedIndex += 1
    if screen.selectedIndex >= screen.levelMetas.len:
      screen.selectedIndex = 0
  elif kButtonDown in buttonState.pushed:
    screen.selectedIndex += 1
    if screen.selectedIndex >= screen.levelMetas.len:
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
    0, screen.levelMetas.high
  )
  for level in screen.levelMetas[screen.scrollPosition .. maxIdx]:
    gfx.drawText(level.name, borderInset * 2, y)
    y += 20
  let cursorY = 40 + 20 * (screen.selectedIndex - screen.scrollPosition)
  gfx.drawText(">", borderInset + 8, cursorY)

proc drawButtons(screen: LevelSelectScreen) =
  discard
  let selectedFileName = screen.levelMetas[screen.selectedIndex].name
  gfx.drawTextAligned("Ⓐ Play " & selectedFileName, 200, 218)

proc draw(screen: LevelSelectScreen) =
  gfx.clear(kColorWhite)
  drawBackground()
  drawTitle("Select a level")
  drawLevelPaths(screen)
  drawButtons(screen)

proc refreshLevelMetas(screen: LevelSelectScreen) =
  var levelPaths = getLevelPaths()
  for levelMeta in levels.values:
    let metaIndex = levelPaths.find(levelMeta.path)
    if metaIndex >= 0:
      screen.levelMetas.add(levelMeta)
      levelPaths.del(metaIndex)
  print "unknown levels: ", repr(levelPaths)

  for levelPath in levelPaths:
    # for unknown levels, add them to the list using path as name
    let levelMeta = newLevelMeta(
      levelPath,
      levelPath
    )
    screen.levelMetas.add(levelMeta)

method resume*(screen: LevelSelectScreen) =
  try:
    screen.refreshLevelMetas()
  except IOError:
    print("Error reading level paths")

  print("metas: ")
  print(repr(screen.levelMetas))

  discard playdate.system.addMenuItem("Settings", proc(menuItem: PDMenuItemButton) =
    pushScreen(newSettingsScreen())
  )

method update*(screen: LevelSelectScreen): int =
  updateInput(screen)
  draw(screen)
  return 1

method `$`*(screen: LevelSelectScreen): string =
  return "LevelSelectScreen"

import playdate/api
import navigation/[screen, navigator]
import common/utils
import data_store/configuration
import level_meta/level_data
import level_select_types
import level_select_view
import screens/game/game_screen
import screens/settings/settings_screen
import tables


const 
  levelsBasePath = "levels/"

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
  elif screen.selectedIndex > screen.scrollPosition + LEVEL_SELECT_VISIBLE_ROWS - 1:
    screen.scrollPosition = screen.selectedIndex - LEVEL_SELECT_VISIBLE_ROWS + 1

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
  initLevelSelectView()
  resumeLevelSelectView()
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

{.push raises: [].}

import playdate/api
import navigation/[screen, navigator]
import common/utils
import std/sequtils
import data_store/configuration
import data_store/user_profile
import level_meta/level_data
import level_select_types
import level_select_view
import screens/game/game_screen
import screens/settings/settings_screen
import math
import tables



proc getLevelPaths(): seq[string] =
  try:
    return playdate.file.listFiles(levelsBasePath).mapIt(levelsBasePath & it)
  except IOError:
    print("ERROR reading level paths", getCurrentExceptionMsg())
    return @[]

proc newLevelSelectScreen*(): LevelSelectScreen =
  return LevelSelectScreen(
    levelRows: @[],
    screenType: ScreenType.LevelSelect
  )

proc updateScrollPosition(screen: LevelSelectScreen) =
  screen.scrollTarget = screen.selectedIndex.float32
  screen.scrollTarget = clamp(screen.scrollTarget, 0, (screen.levelRows.len - LEVEL_SELECT_VISIBLE_ROWS).float32)

  screen.scrollPosition += (screen.scrollTarget - screen.scrollPosition) * 0.1
  print("scrollPos", screen.scrollPosition)

  # if screen.selectedIndex < screen.scrollPosition:
  #   screen.scrollPosition = screen.selectedIndex
  # elif screen.selectedIndex > screen.scrollPosition + LEVEL_SELECT_VISIBLE_ROWS - 1:
  #   screen.scrollPosition = screen.selectedIndex - LEVEL_SELECT_VISIBLE_ROWS + 1

proc updateInput(screen: LevelSelectScreen) =
  let buttonState = playdate.system.getButtonState()
  let rows = screen.levelRows
  let numRows = rows.len

  if kButtonA in buttonState.pushed:
    let levelPath = rows[screen.selectedIndex].levelMeta.path
    let gameScreen = newGameScreen(levelPath)
    # the ganme screen loaded successfully, save as last opened level
    setLastOpenedLevel(levelPath)
    pushScreen(gameScreen)
  elif kButtonUp in buttonState.pushed:
    screen.selectedIndex -= 1
    if screen.selectedIndex < 0:
      screen.selectedIndex = numRows - 1
  elif kButtonDown in buttonState.pushed:
    screen.selectedIndex += 1
    if screen.selectedIndex >= numRows:
      screen.selectedIndex = 0
  elif kButtonDown in buttonState.pushed:
    screen.selectedIndex += 1
    if screen.selectedIndex >= numRows:
      screen.selectedIndex = 0

  updateScrollPosition(screen)

proc newLevelRow(levelMeta: LevelMeta): LevelRow =
  return LevelRow(
    levelMeta: levelMeta,
    progress: getOrInsertProgress(levelMeta.path)
  )


proc refreshLevelRows(screen: LevelSelectScreen) =
  var levelPaths = getLevelPaths()
  for levelMeta in officialLevels.values:
    let metaIndex = levelPaths.find(levelMeta.path)
    if metaIndex >= 0:
      screen.levelRows.add(levelMeta.newLevelRow())
      levelPaths.del(metaIndex)
  print "unknown levels: ", repr(levelPaths)

  for levelPath in levelPaths:
    # for unknown levels, add them to the list using path as name
    let levelMeta = newLevelMeta(
      levelPath,
      levelPath
    )
    screen.levelRows.add(levelMeta.newLevelRow())

method resume*(screen: LevelSelectScreen) =
  initLevelSelectView()
  resumeLevelSelectView()
  try:
    screen.refreshLevelRows()
  except IOError:
    print("Error reading level paths")

  print("rows: ")
  print(repr(screen.levelRows))

  discard playdate.system.addMenuItem("Settings", proc(menuItem: PDMenuItemButton) =
    pushScreen(newSettingsScreen())
  )

method update*(screen: LevelSelectScreen): int =
  updateInput(screen)
  draw(screen)
  return 1

method `$`*(screen: LevelSelectScreen): string =
  return "LevelSelectScreen"

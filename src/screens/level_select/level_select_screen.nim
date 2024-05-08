{.push raises: [].}

import playdate/api
import navigation/[screen, navigator]
import common/utils
import common/shared_types
import std/sequtils
import std/options
import data_store/configuration
import data_store/user_profile
import level_meta/level_data
import level_select_types
import level_select_view
import screens/game/game_screen
import screens/settings/settings_screen
import tables

const
  initialUnlockedLevels = 3
  pushedButtonTimeout = 0.3.Seconds
  heldButtonTimeout = 0.2.Seconds

var
  backgroundAudioPlayer: FilePlayer

proc initLevelSelectScreen() =
  backgroundAudioPlayer = try: playdate.sound.newFilePlayer("/audio/level_select/ambience") 
  except:
    playdate.system.error(getCurrentExceptionMsg())
    nil

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
  screen.scrollTarget = screen.selectedIndex.float32 - LEVEL_SELECT_VISIBLE_ROWS / 2 + 0.8f
  screen.scrollTarget = clamp(screen.scrollTarget, 0f, screen.levelRows.len.float32 - LEVEL_SELECT_VISIBLE_ROWS)

  screen.scrollPosition = lerp(
    screen.scrollPosition, 
    screen.scrollTarget, 
    0.2
  )

proc selectPreviousRow(screen: LevelSelectScreen, immediately: bool) =
  if screen.selectedIndex <= 0 and screen.firstLockedRowIdx.get(screen.levelRows.len) < screen.levelRows.len:
    if immediately: screen.scrollPosition = -1f
    return
  screen.downActivatedAt = none(Seconds)
  if immediately or currentTimeSeconds() > screen.upActivatedAt.get(0):
    screen.selectedIndex -= 1
    if screen.selectedIndex < 0:
      screen.selectedIndex = screen.levelRows.len - 1
    let timeout: Seconds = if screen.upActivatedAt.isNone: pushedButtonTimeout else: heldButtonTimeout
    screen.upActivatedAt = some(currentTimeSeconds() + timeout)

proc selectNextRow(screen: LevelSelectScreen, immediately: bool) =
  if screen.selectedIndex >= screen.firstLockedRowIdx.get(screen.levelRows.len) - 1:
    if immediately: screen.scrollPosition += 1f
    return  

  screen.upActivatedAt = none(Seconds)
  if immediately or currentTimeSeconds() > screen.downActivatedAt.get(0):
    screen.selectedIndex += 1
    if screen.selectedIndex >= screen.levelRows.len:
      screen.selectedIndex = 0
    let timeout: Seconds = if screen.downActivatedAt.isNone: pushedButtonTimeout else: heldButtonTimeout
    screen.downActivatedAt = some(currentTimeSeconds() + timeout)


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
  elif kButtonUp in buttonState.current:
    selectPreviousRow(screen, kbuttonUp in buttonState.pushed)
  elif kButtonDown in buttonState.current:
    selectNextRow(screen, kButtonDown in buttonState.pushed)
  elif kButtonDown in buttonState.pushed:
    screen.selectedIndex += 1
    if screen.selectedIndex >= numRows:
      screen.selectedIndex = 0

  updateScrollPosition(screen)

proc newLevelRow(levelMeta: LevelMeta): LevelRow =
  return LevelRow(
    levelMeta: levelMeta,
    progress: getLevelProgress(levelMeta.path)
  )


proc refreshLevelRows(screen: LevelSelectScreen) =
  screen.levelRows.setLen(0)
  var numLevelsUnlocked = 0
  var levelPaths = getLevelPaths()
  for levelMeta in officialLevels.values:
    let metaIndex = levelPaths.find(levelMeta.path)
    if metaIndex >= 0:
      let levelRow = levelMeta.newLevelRow()
      screen.levelRows.add(levelRow)
      levelPaths.del(metaIndex)
      if levelRow.progress.bestTime.isSome:
        inc numLevelsUnlocked
  
  screen.firstLockedRowIdx = some(initialUnlockedLevels + numLevelsUnlocked + levelPaths.len)

  print "unknown levels: ", repr(levelPaths)
  print "firstLockedRowIdx: ", screen.firstLockedRowIdx

  for levelPath in levelPaths:
    # for unknown levels, add them to the list using path as name
    let levelMeta = newLevelMeta(
      levelPath,
      levelPath
    )
    screen.levelRows.insert(levelMeta.newLevelRow())

method resume*(screen: LevelSelectScreen) =
  screen.upActivatedAt = none(Seconds)
  screen.downActivatedAt = none(Seconds)
  try:
    screen.refreshLevelRows()
  except IOError:
    print("Error reading level paths")

  print("rows: ")
  print(repr(screen.levelRows))

  initLevelSelectScreen()
  initLevelSelectView()
  resumeLevelSelectView()
  backgroundAudioPlayer.play(0)

  discard playdate.system.addMenuItem("Settings", proc(menuItem: PDMenuItemButton) =
    pushScreen(newSettingsScreen())
  )

method update*(screen: LevelSelectScreen): int =
  updateInput(screen)
  draw(screen)
  return 1

method `$`*(screen: LevelSelectScreen): string =
  return "LevelSelectScreen"

{.push raises: [], warning[LockLevel]:off.}

import playdate/api
import navigation/[screen, navigator]
import common/utils
import common/shared_types
import common/audio_utils
import std/sequtils
import std/strutils
import std/options
import std/tables
import std/sugar
import cache/sound_cache
import data_store/user_profile
import level_meta/level_data
import level_select_types
import level_select_view
import screens/screen_types
import screens/cutscene/cutscene_screen
import screens/settings/settings_screen

const
  initialUnlockedLevels = 30
  pushedButtonTimeout = 0.3.Seconds
  heldButtonTimeout = 0.2.Seconds

var
  backgroundAudioPlayer: FilePlayer
  confirmPlayer: SamplePlayer
  selectNextPlayer, selectPreviousPlayer, selectBumperPlayer: SamplePlayer

proc initLevelSelectScreen() =
  if not backgroundAudioPlayer.isNil:
    print("initLevelSelectScreen: already initialized")
    return

  backgroundAudioPlayer = try: playdate.sound.newFilePlayer("/audio/level_select/ambience") 
  except:
    playdate.system.error(getCurrentExceptionMsg())
    nil
  
  selectPreviousPlayer = getOrLoadSamplePlayer("audio/menu/select_previous")
  selectNextPlayer = getOrLoadSamplePlayer("audio/menu/select_next")
  confirmPlayer = getOrLoadSamplePlayer("audio/menu/confirm")
  selectBumperPlayer = getOrLoadSamplePlayer("audio/menu/bumper")


proc getLevelPaths(): seq[string] =
  try:
    return playdate.file.listFiles(levelsBasePath)
      .filterIt(it.endsWith(levelFileExtension))
      .mapIt(levelsBasePath & it)
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

proc selectRow(screen: LevelSelectScreen, idx: int) =
  screen.selectedIndex = idx
  # wrap around
  if screen.selectedIndex < 0:
    screen.selectedIndex = screen.levelRows.high
  elif screen.selectedIndex > screen.levelRows.high:
    screen.selectedIndex = 0

  screen.levelTheme = screen.levelRows[screen.selectedIndex].levelMeta.theme

proc selectPreviousRow(screen: LevelSelectScreen, immediately: bool) =
  if screen.selectedIndex <= 0 and screen.firstLockedRowIdx.get(screen.levelRows.len) < screen.levelRows.len:
    if immediately: 
      screen.scrollPosition = -1f
      selectBumperPlayer.playVariation()
    return
  screen.downActivatedAt = none(Seconds)
  if immediately or currentTimeSeconds() > screen.upActivatedAt.get(0):
    selectPreviousPlayer.play()
    screen.selectRow(screen.selectedIndex - 1)
    let timeout: Seconds = if screen.upActivatedAt.isNone: pushedButtonTimeout else: heldButtonTimeout
    screen.upActivatedAt = some(currentTimeSeconds() + timeout)

proc selectNextRow(screen: LevelSelectScreen, immediately: bool) =
  if screen.selectedIndex >= screen.firstLockedRowIdx.get(screen.levelRows.len) - 1:
    if immediately: 
      screen.scrollPosition += 1f
      selectBumperPlayer.playVariation()
    return  

  screen.upActivatedAt = none(Seconds)
  if immediately or currentTimeSeconds() > screen.downActivatedAt.get(0):
    selectNextPlayer.play()
    screen.selectRow(screen.selectedIndex + 1)
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
    confirmPlayer.playVariation
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
      name = levelPath[levelsBasePath.len .. ^1],
      path = levelPath,
      hash = "no hash: user level",
      theme = LevelTheme.Space
    )
    screen.levelRows.insert(levelMeta.newLevelRow())

proc getInitialRowIdx(screen: LevelSelectScreen): int =
  let optLastOpenedLevel = getSaveSlot().lastOpenedLevel
  if optLastOpenedLevel.isSome:
    let lastOpenedLevelPath = optLastOpenedLevel.get
    let (previousRowIdx, _) = screen.levelRows.findFirstIndexed(it => it.levelMeta.path == lastOpenedLevelPath)
    if previousRowIdx >= 0:
      return previousRowIdx
  return 0

proc addMenuItemWorkaround(title: string, callback: proc(state: LuaStatePtr): cint {.cdecl, raises: [].}): PDMenuItemButton =
  # This is a workaround for a bug in the SDK where a crash occurs when the menu item is selected
  
  try:
    playdate.lua.pushString(title)
    playdate.lua.pushFunction(callback)
    playdate.lua.callFunction("LuaAddMenuItemWorkaround", 2)
  except:
    print "Error adding menu item"
  
  return nil

method resume*(screen: LevelSelectScreen) =
  screen.upActivatedAt = none(Seconds)
  screen.downActivatedAt = none(Seconds)
  try:
    screen.refreshLevelRows()
  except IOError:
    print("Error reading level paths")

  initLevelSelectScreen()
  initLevelSelectView()

  screen.selectRow(getInitialRowIdx(screen))

  resumeLevelSelectView(screen)
  backgroundAudioPlayer.play(0)

  discard playdate.system.addMenuItem("Panels Test", proc(menuItem: PDMenuItemButton) =
    pushScreen(newCutSceneScreen())
  )

  # todo move to utils and use everywhere where menu items are added
  discard addMenuItemWorkaround("Settings", proc(state: LuaStatePtr): cint {.cdecl, raises: [].} =
    let argCount = playdate.lua.getArgCount()
    print(fmt"Nim callback with {argCount} argument(s)")
    pushScreen(newSettingsScreen())
  )


method pause*(screen: LevelSelectScreen) =
  backgroundAudioPlayer.stop()

method update*(screen: LevelSelectScreen): int =
  updateInput(screen)
  draw(screen)
  return 1

method `$`*(screen: LevelSelectScreen): string =
  return "LevelSelectScreen"

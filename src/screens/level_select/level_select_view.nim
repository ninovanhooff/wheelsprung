import playdate/api
import level_select_types
import std/tables
import math
import common/shared_types
import common/graphics_utils
import common/lcd_patterns
import common/utils
import common/score_utils
import std/options
import cache/bitmap_cache
import cache/bitmaptable_cache
import cache/font_cache
import level_meta/level_data

const 
  borderInset = 7
  verticalLines = [199, 219, 279]
    ## x positions of vertical table cell dividers relative to levelDrawRegion.x
  rowHeight = 20
  emptyTimeText = "--:--.--"
  scrollEpsilon = 1.0f / rowHeight # 1 pixel of scroll
    ## how much scroll slop is allowed to stop drawing screen

let 
  levelDrawRegion = Rect(x: 30,y: 70, width: 342, height:110)

var 
  levelStatusImages: AnnotatedBitmapTable
  levelFont: LCDFont
  activeLevelTheme: LevelTheme
  rowsBitmap: LCDBitmap
  rowDrawState = initTable[int32, bool]()

proc initLevelSelectView*() =
  if not levelStatusImages.isNil: return # already initialized
    
  levelStatusImages = getOrLoadBitmapTable(BitmapTableId.LevelStatus)
  levelFont = getOrLoadFont(FontId.M6X11)

proc getBackground(levelTheme: LevelTheme): LCDBitmap =
  case levelTheme
  of LevelTheme.Kitchen: return getOrLoadBitmap(LevelSelectBgKitchen)
  of LevelTheme.Bath: return getOrLoadBitmap(LevelSelectBgBath)
  of LevelTheme.Bookshelf: return getOrLoadBitmap(LevelSelectBgBookshelf)
  of LevelTheme.Desk: return getOrLoadBitmap(LevelSelectBgDesk)
  of LevelTheme.Space: return getOrLoadBitmap(LevelSelectBgSpace)
  of LevelTheme.Plants: return getOrLoadBitmap(LevelSelectBgPlants)

proc drawBackground(levelTheme: LevelTheme) =
  levelTheme.getBackground().draw(0, 0, kBitmapUnflipped)
  activeLevelTheme = levelTheme

proc getLevelStatusImage(progress: LevelProgress): LCDBitmap =
  if progress.bestTime.isNone:
    return levelStatusImages.getBitmap(0)
  elif progress.hasCollectedStar:
    return levelStatusImages.getBitmap(2)
  else:
    return levelStatusImages.getBitmap(1)

proc timeText(progress: LevelProgress): string =
  if progress.bestTime.isNone:
    return emptyTimeText
  else:
    return progress.bestTime.get.formatTime()

proc isCurrentPlayerLeader(row: LevelRow): bool =
  return row.progress.bestTime.isSome and row.optLeaderScore.isSome and 
    row.progress.bestTime.get <= row.optLeaderScore.get.scoreToTime

proc leaderText(row: LevelRow): string =
  if isCurrentPlayerLeader(row):
    return "YOU"
  elif row.optLeaderScore.isSome:
    if row.progress.bestTime.isSome:
      let diff = row.progress.bestTime.get - row.optLeaderScore.get.scoreToTime
      return diff.formatTime(signed = true, trim = true)
    else:
      return row.optLeaderScore.get.uint32.scoreToTimeString(signed = false)
  else:
    return emptyTimeText



proc initTableRowsImage(screen: LevelSelectScreen, forceRedraw: bool) =
  let requiredHeight = screen.levelRows.len * rowHeight
  if not rowsBitmap.isNil and 
    rowsBitmap.height == requiredHeight and
    not forceRedraw: 
      return
  
  rowsBitmap = gfx.newBitmap(levelDrawRegion.width, requiredHeight, kColorWhite)
  
  gfx.pushContext(rowsBitmap)
  for x in verticalLines:
    gfx.drawLine(x, 0, x, requiredHeight, 2, kColorBlack)
  gfx.popContext()
  
  rowDrawState.clear()

proc renderLevelRow(idx: int32, row: LevelRow) =
  gfx.pushContext(rowsBitmap)
  let x = 0
  let y = idx * rowHeight
  let levelMeta = row.levelMeta
  let progress = row.progress
  let nameText: string = fmt"{idx + 1}. {levelMeta.name}"
  gfx.drawText(nameText, x + borderInset, y+4)

  let statusImage = getLevelStatusImage(progress)
  statusImage.draw(x + 200, y + 2, kBitmapUnflipped)

  gfx.drawText(progress.timeText, verticalLines[1] + 6, y+4)
  gfx.drawTextAligned(row.leaderText, verticalLines[2] + 60, y+4, kTextAlignmentRight)
  gfx.popContext()
  rowDrawState[idx] = true

proc drawLockedLevelsScrim(screen: LevelSelectScreen) =
  if screen.firstLockedRowIdx.isNone:
    return

  let rowIdx = screen.firstLockedRowIdx.get

  var scrimY = levelDrawRegion.y + ((-screen.scrollPosition + rowIdx.float32) * rowHeight).round.int32


  gfx.fillRect(
    levelDrawRegion.x, scrimY, 
    levelDrawRegion.width, screen.levelRows.len * rowHeight, # fill to the bottom of the screen
    patGrayTransparent
  )
  gfx.drawLine(
    levelDrawRegion.x, scrimY, 
    levelDrawRegion.x + levelDrawRegion.width, scrimY, 
    2, kColorBlack
  )

proc drawLevelRows(screen: LevelSelectScreen, forceRedraw: bool = false) =
  initTableRowsImage(screen, forceRedraw)
  let scrollPosition = screen.scrollPosition
  var y = levelDrawRegion.y - ((scrollPosition mod 1.0f) * rowHeight).round.int32
  let maxRenderIdx = clamp(
    screen.scrollPosition.int + LEVEL_SELECT_VISIBLE_ROWS.ceil.int32, 
    0, screen.levelRows.high
  ).int32

  var rowIdx: int32 = -1
  var row: LevelRow = nil
  for idx in scrollPosition.int32 .. maxRenderIdx:
    if not rowDrawState.hasKey(idx):
      rowIdx = idx
      row = screen.levelRows[rowIdx]
      renderLevelRow(rowIdx, row)
  
  if rowIdx == -1 and abs(screen.scrollPosition - screen.scrollTarget) < scrollEpsilon and
    # rowIdx == -1: no rows where updated
    not screen.isSelectionDirty and
    not forceRedraw:
    return

  gfx.setClipRect(levelDrawRegion.x, levelDrawRegion.y, levelDrawRegion.width, levelDrawRegion.height)

  rowsBitmap.draw(levelDrawRegion.x, levelDrawRegion.y - (scrollPosition * rowHeight).int32, kBitmapUnflipped)

  # invert the selected row
  let selectedRowY = y + (screen.selectedIndex - scrollPosition.int32) * rowHeight
  gfx.fillRect(
    levelDrawRegion.x, selectedRowY, 
    levelDrawRegion.width, rowHeight, 
    kColorXOR
  )

  drawLockedLevelsScrim(screen)

  gfx.clearClipRect()

proc draw*(screen: LevelSelectScreen, forceRedraw: bool = false) =
  if activeLevelTheme != screen.levelTheme or forceRedraw:
    drawBackground(screen.levelTheme)
  drawLevelRows(screen, forceRedraw)


proc resumeLevelSelectView*(screen: LevelSelectScreen) =
  gfx.setFont(levelFont)
  screen.draw(forceRedraw = true)

import playdate/api
import level_select_types
import math
import common/graphics_types
import common/lcd_patterns
import common/utils
import options
import cache/bitmap_cache
import cache/bitmaptable_cache
import cache/font_cache
import level_meta/level_data

const 
  borderInset = 7
  verticalLines = [229, 249, 309]
    ## x positions of vertical table cell dividers
  rowHeight = 20

let 
  levelDrawRegion = Rect(x: 30,y: 70, width: 342, height:110)

var 
  levelStatusImages: AnnotatedBitmapTable
  levelFont: LCDFont
  activeLevelTheme: LevelTheme

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
    return "--:--.--"
  else:
    return progress.bestTime.get.formatTime()

proc drawLevelRows(screen: LevelSelectScreen) =
  let x = levelDrawRegion.x
  let scrollPosition = screen.scrollPosition
  var y = levelDrawRegion.y - ((scrollPosition mod 1.0f) * rowHeight).round.int32
  let maxIdx = clamp(
    screen.scrollPosition.int + LEVEL_SELECT_VISIBLE_ROWS.ceil.int32, 
    0, screen.levelRows.high
  ).int32

  # Draw the selected row background
  let selectedRowY = y + (screen.selectedIndex - scrollPosition.int32) * rowHeight
  gfx.fillRect(
    levelDrawRegion.x, selectedRowY, 
    levelDrawRegion.width, rowHeight, 
    kColorXOR
  )

  for idx, row in screen.levelRows[scrollPosition.int32 .. maxIdx]:
    let levelMeta = row.levelMeta
    let progress = row.progress
    let displayIdx = idx + scrollPosition.int32 + 1
    let nameText: string = fmt"{displayIdx}. {levelMeta.name}"
    gfx.drawText(nameText, x + borderInset, y+4)

    let statusImage = getLevelStatusImage(progress)
    statusImage.draw(x + 200, y + 2, kBitmapUnflipped)

    gfx.drawText(progress.timeText, verticalLines[1] + 6, y+4)
    y += 20

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

proc prepareDrawRegion(screen: LevelSelectScreen) =
  gfx.clear(kColorWhite)
  for x in verticalLines:
    gfx.drawLine(x, levelDrawRegion.y, x, levelDrawRegion.y + levelDrawRegion.height, 2, kColorBlack)

proc draw*(screen: LevelSelectScreen) =
  if activeLevelTheme != screen.levelTheme:
    drawBackground(screen.levelTheme)
    
  gfx.setClipRect(levelDrawRegion.x, levelDrawRegion.y, levelDrawRegion.width, levelDrawRegion.height)

  prepareDrawRegion(screen)
  gfx.setDrawMode(kDrawModeNXOR)
  drawLevelRows(screen)
  gfx.setDrawMode(kDrawModeCopy)
  drawLockedLevelsScrim(screen)
  
  gfx.clearClipRect()


proc resumeLevelSelectView*(screen: LevelSelectScreen) =
  gfx.setFont(levelFont)
  drawBackground(screen.levelTheme)

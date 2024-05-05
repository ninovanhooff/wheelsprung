import playdate/api
import level_select_types
import common/graphics_types
import common/utils
import options
import cache/bitmap_cache
import cache/bitmaptable_cache
import cache/font_cache

const 
  borderInset = 7
  verticalLines = [229, 249, 309]
    ## x positions of vertical table cell dividers
  rowHeight = 20

let 
  levelDrawRegion = Rect(x: 30,y: 70, width: 342, height:110)

var 
  backgroundBitmap: LCDBitmap
  levelStatusImages: AnnotatedBitmapTable
  levelFont: LCDFont

proc initLevelSelectView*() =
  if not backgroundBitmap.isNil: return # already initialized
    
  backgroundBitmap = getOrLoadBitmap("images/level_select/select-bg")
  levelStatusImages = getOrLoadBitmapTable(BitmapTableId.LevelStatus)
  levelFont = getOrLoadFont("fonts/m6x11-12.pft")

proc drawBackground() =
  backgroundBitmap.draw(0, 0, kBitmapUnflipped)

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
  var y = levelDrawRegion.y
  let maxIdx = clamp(
    screen.scrollPosition + LEVEL_SELECT_VISIBLE_ROWS - 1, 
    0, screen.levelRows.high
  )

  for idx, row in screen.levelRows[scrollPosition .. maxIdx]:
    let levelMeta = row.levelMeta
    let progress = row.progress
    let displayIdx = idx + scrollPosition + 1
    let nameText: string = fmt"{displayIdx}. {levelMeta.name}"
    gfx.drawText(nameText, x + borderInset, y+4)

    let statusImage = getLevelStatusImage(progress)
    statusImage.draw(x + 200, y + 2, kBitmapUnflipped)

    gfx.drawText(progress.timeText, verticalLines[1] + 6, y+4)
    y += 20

proc drawSelection(screen: LevelSelectScreen) =
  let selectedRowY = levelDrawRegion.y + rowHeight * (screen.selectedIndex - screen.scrollPosition)
  gfx.fillRect(
    levelDrawRegion.x, selectedRowY, 
    levelDrawRegion.width, rowHeight, 
    kColorXOR
  )

proc prepareDrawRegion(screen: LevelSelectScreen) =
  gfx.setClipRect(levelDrawRegion.x, levelDrawRegion.y, levelDrawRegion.width, levelDrawRegion.height)
  gfx.clear(kColorWhite)
  for x in verticalLines:
    gfx.drawLine(x, levelDrawRegion.y, x, levelDrawRegion.y + levelDrawRegion.height, 2, kColorBlack)

proc draw*(screen: LevelSelectScreen) =
  prepareDrawRegion(screen)
  gfx.setDrawMode(kDrawModeNXOR)
  drawSelection(screen)
  drawLevelRows(screen)

proc resumeLevelSelectView*() =
  gfx.setFont(levelFont)
  drawBackground()

import playdate/api
import level_select_types
import common/graphics_types
import cache/bitmap_cache
import cache/font_cache

const 
  borderInset = 7
  verticalLines = [229, 249, 309]
    ## x positions of vertical table cell dividers
  rowHeight = 20

let 
  levelDrawRegion = Rect(x: 30,y: 70, width: 342, height:110)

var backgroundBitmap: LCDBitmap
var levelFont: LCDFont

proc initLevelSelectView*() =
  if not backgroundBitmap.isNil: return # already initialized
    
  backgroundBitmap = getOrLoadBitmap("images/level_select/select-bg")
  levelFont = getOrLoadFont("fonts/m6x11-12.pft")

proc drawBackground() =
  backgroundBitmap.draw(0, 0, kBitmapUnflipped)

proc drawLevelPaths(screen: LevelSelectScreen) =
  let x = levelDrawRegion.x
  let scrollPosition = screen.scrollPosition
  var y = levelDrawRegion.y
  let maxIdx = clamp(
    screen.scrollPosition + LEVEL_SELECT_VISIBLE_ROWS - 1, 
    0, screen.levelMetas.high
  )
  for idx, level in screen.levelMetas[scrollPosition .. maxIdx]:
    let displayIdx = idx + scrollPosition + 1
    let text: string = fmt"{displayIdx}. {level.name}"
    gfx.drawText(text, x + borderInset, y+4)
    y += 20

proc drawButtons(screen: LevelSelectScreen) =
  discard
  let selectedFileName = screen.levelMetas[screen.selectedIndex].name
  gfx.drawTextAligned("Ⓐ Play " & selectedFileName, 200, 218)

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
  drawLevelPaths(screen)
  drawButtons(screen)

proc resumeLevelSelectView*() =
  gfx.setFont(levelFont)
  drawBackground()

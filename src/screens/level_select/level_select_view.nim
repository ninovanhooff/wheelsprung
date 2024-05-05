import playdate/api
import level_select_types
import common/graphics_types
import cache/bitmap_cache

const 
  borderInset = 24

var backgroundBitmap: LCDBitmap

proc initLevelSelectView*() =
  if not backgroundBitmap.isNil: return # already initialized
    
  backgroundBitmap = getOrLoadBitmap("level_select/sselect-bg.png")

proc drawBackground() =
  discard # backgroundBitmap.draw(0, 0, kBitmapUnflipped)

proc drawTitle(title: string) =
  gfx.drawTextAligned(title, 200, 2)

proc drawLevelPaths(screen: LevelSelectScreen) =
  var y = 40
  let maxIdx = clamp(
    screen.scrollPosition + LEVEL_SELECT_VISIBLE_ROWS - 1, 
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

proc draw*(screen: LevelSelectScreen) =
  gfx.clear(kColorWhite)
  drawBackground()
  drawTitle("Select a level")
  drawLevelPaths(screen)
  drawButtons(screen)
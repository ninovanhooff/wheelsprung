import playdate/api
import common/graphics_utils
import screens/game/game_types
import cache/font_cache
import cache/bitmaptable_cache

var readyGoBitmapTable: AnnotatedBitmapTable
var titleFont: LCDFont
var isGameStartOverlayInitialized = false

proc initGameStartOverlay*() =
  if isGameStartOverlayInitialized: return
    
  readyGoBitmapTable = getOrLoadBitmapTable(BitmapTableId.ReadyGo)
  titleFont = getOrLoadFont(FontId.M6X11)
  isGameStartOverlayInitialized = true

proc getIsGameStartOverlayInitialized*(): bool =
  return isGameStartOverlayInitialized

proc getReadyGoFrameCount*(): int =
  return readyGoBitmapTable.frameCount

proc drawGameStartOverlay*(state: GameStartState) =
  if not isGameStartOverlayInitialized: return

  let name = state.levelName
  let (textW, textH) = titleFont.getTextSize(name)
  let textRect = Rect(
    x: 18,
    y: 216,
    width: textW.int32,
    height: textH.int32
  )
  textRect.inset(-4,-4, -4, -2).fillRoundRect(
    radius=4,
    color=kColorBlack
  )
  gfx.setFont(titleFont)
  gfx.setDrawMode(kDrawModeFillWhite)
  gfx.drawText(name, textRect.x, textRect.y)
  gfx.setDrawMode(kDrawModeCopy)
  
  readyGoBitmapTable.getBitmap(state.readyGoFrame).draw(113, 4, kBitmapUnflipped)
import playdate/api
import common/graphics_utils
import game_types
import cache/font_cache
import cache/bitmaptable_cache
import common/utils

proc drawGameStart*(state: GameState) =
  let titleFont = getOrLoadFont(FontId.M6X11)
  let readyGo = getOrLoadBitmapTable(BitmapTableId.ReadyGo)
  let name = state.level.meta.name
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

  readyGo.getBitmap(0).draw(0, 0, kBitmapUnflipped)

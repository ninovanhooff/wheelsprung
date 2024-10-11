import playdate/api
import common/graphics_utils
import game_types
import cache/font_cache

proc drawGameStart*(state: GameState) =
  let titleFont = getOrLoadFont(FontId.M6X11)
  let name = state.level.meta.name
  let (textW, textH) = titleFont.getTextSize(name)
  let textRect = Rect(
    x: 18,
    y: 216,
    width: textW.int32,
    height: textH.int32
  )
  textRect.inset(-4,-4).fill(kColorBlack)
  gfx.setFont(titleFont)
  gfx.setDrawMode(kDrawModeFillWhite)
  gfx.drawText(name, textRect.x, textRect.y)
  gfx.setDrawMode(kDrawModeCopy)

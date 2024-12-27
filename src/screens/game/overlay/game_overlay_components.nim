{.push raises: [].}

import playdate/api
import common/graphics_types
import common/graphics_utils
import cache/font_cache

proc drawButtonMapOverlay*(text: string) =
  let smallFont = getOrLoadFont(FontId.Roobert10Bold)
  gfx.setFont(smallFont)
  gfx.setDrawMode(kDrawModeFillWhite)
  let (textW, textH) = smallFont.getTextSize(text)
  let textRect = Rect(
    x: LCD_COLUMNS div 2 - textW.int32 div 2,
    y: 216,
    width: textW.int32,
    height: textH.int32
  )
  textRect.inset(-3,-3, -3, -2).fillRoundRect(
    radius=4,
    color=kColorBlack
  )
  gfx.setDrawMode(kDrawModeFillWhite)
  gfx.drawText(text, textRect.x, textRect.y)
  gfx.setDrawMode(kDrawModeCopy)
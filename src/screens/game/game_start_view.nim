import playdate/api
import common/graphics_utils
import game_types
import cache/font_cache
import chipmunk7

proc drawGameStart*(state: GameState) =
  gfx.setFont(getOrLoadFont(FontId.M6X11))
  let messageY = (state.riderHead.position.y - state.camera.y - 26.0).int32
  if not state.isGameStarted:
    gfx.drawTextAligned("Ready?", 200, messageY)
  else:
    gfx.drawTextAligned("Go!", 200, messageY)
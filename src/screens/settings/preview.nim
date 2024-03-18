import playdate/api
import utils
import graphics_utils, graphics_types
import shared_types
import input_response
import configuration_types

proc drawDPadInputResponsePreview*(config: Config, rect: Rect) =
  rect.fill(kColorWhite)
  rect.inset(4).draw(kColorBlack)
  let graphRect = rect.inset(40,2, 40, 4)
  gfx.drawTextAligned("Force".vertical, graphRect.x, graphRect.y + 6, lineHeightAdjustment = -6)
  let axisRect = graphRect.inset(20,4)
  let axisRectBottom = axisRect.bottom
  gfx.drawLine(axisRect.x, axisRect.y, axisRect.x, axisRectBottom, 1, kColorBlack)
  gfx.drawLine(
    axisRect.x, axisRectBottom, 
    axisRect.right, axisRectBottom, 
    1, kColorBlack
  )

  let plotRect = axisRect.inset(2)
  let plotBottomY = plotRect.bottom
  let inputResponse = config.toInputResponse()

  let xStep: int32 = (plotRect.width / 50).int32
  var x = plotRect.x
  var y, lastY = 0
  for tick in 0..50:
    let response = inputResponse(tick.Seconds * 0.02.Seconds)
    y = clamp(plotBottomY - (response / 500.0f).int32, plotRect.y, plotRect.bottom)
    if tick > 0:
      gfx.drawLine(x - xStep, lastY, x, y, 2, kColorBlack)
    x += xStep
    lastY = y
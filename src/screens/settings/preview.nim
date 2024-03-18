import playdate/api
import graphics_utils, graphics_types
import configuration_types

proc drawDPadInputResponsePreview*(config: Config, rect: Rect) =
  rect.fill(kColorBlack)
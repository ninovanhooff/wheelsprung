import playdate/api
import leaderboards_types
import common/graphics_utils

proc draw*(screen: LeaderboardsScreen, forceRedraw: bool = false)=
  gfx.clear(kColorWhite)
  discard
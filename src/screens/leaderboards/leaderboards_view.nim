import playdate/api
import leaderboards_types
import common/graphics_utils
import cache/font_cache

proc draw*(screen: LeaderboardsScreen, forceRedraw: bool = false)=
  if screen.pages.len == 0:
    return
  let page = screen.pages[screen.currentPageIdx]
  gfx.clear(kColorWhite)
  gfx.setFont(getOrLoadFont(FontId.Roobert10Bold))

  var y = 10
  for i in 0 ..< page.scores.len:
    let score = page.scores[i]
    gfx.drawText($score.rank, 10, y)
    gfx.drawText(score.player, 30, y)
    gfx.drawText($score.value, 100, y)
    y += 14
  
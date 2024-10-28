import playdate/api
import leaderboards_types
import common/graphics_utils
import cache/font_cache
import common/score_utils

proc draw*(screen: LeaderboardsScreen, forceRedraw: bool = false)=
  if screen.pages.len == 0:
    return
  let page = screen.pages[screen.currentPageIdx]
  gfx.clear(kColorWhite)
  gfx.setFont(getOrLoadFont(FontId.NontendoBold))

  gfx.drawTextAligned(page.boardName, 200, 10)

  if page.scores.len == 0:
    gfx.drawTextAligned("Loading...", 200, 110)
    return

  var y = 50
  for i in 0 ..< page.scores.len:
    let score = page.scores[i]
    gfx.drawText($score.rank, 10, y)
    gfx.drawText(score.player, 30, y)
    gfx.drawText(scoreToTimeString(score.value), 100, y)
    y += 24
  
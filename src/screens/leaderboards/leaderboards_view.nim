import playdate/api
import leaderboards_types
import common/graphics_utils
import cache/font_cache

proc draw*(screen: LeaderboardsScreen, forceRedraw: bool = false)=
  if screen.pages.len == 0:
    return
  let page = screen.pages[screen.currentPageIdx]
  gfx.clear(kColorWhite)
  gfx.setFont(getOrLoadFont(FontId.Roobert11Medium))

  gfx.drawTextAligned(page.boardName, 200, 10)

  if page.scores.len == 0:
    gfx.drawTextAligned("Loading...", 200, 110)
    return

  var y = 50'i32
  gfx.setDrawMode(kDrawModeNXOR)
  for i in 0 ..< page.scores.len:
    let score = page.scores[i]
    if score.isCurrentPlayer:
      fillRoundRect(5, y - 2, LCD_COLUMNS - 10, 24, 4, kColorBlack)
    gfx.drawTextAligned($score.rank, 65, y, kTextAlignmentRight)
    gfx.drawText(score.player, 80, y)
    gfx.drawText(score.timeString, 290, y)
    y += 24
  gfx.setDrawMode(kDrawModeCopy)
  
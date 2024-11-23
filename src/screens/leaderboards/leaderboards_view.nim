import playdate/api
import leaderboards_types
import common/graphics_utils
import cache/font_cache
import cache/bitmap_cache

proc draw*(screen: LeaderboardsScreen, forceRedraw: bool = false)=
  if not screen.isDirty and not forceRedraw: return

  if screen.leaderboards.len == 0:
    return
  let leaderboard = screen.leaderboards[screen.currentLeaderboardIdx]
  getOrLoadBitmap(BitmapId.LeaderboardsBg).draw(0,0, kBitmapUnflipped)
  gfx.setFont(getOrLoadFont(FontId.Roobert11Medium))

  gfx.drawTextAligned(leaderboard.boardName, 200, 10)

  case leaderboard.state.kind:
  of LeaderboardStateKind.Loading:
    gfx.drawTextAligned("Loading...", 200, 110)
  of LeaderboardStateKind.Error:
    gfx.drawTextAligned("Leaderboard not available", 200, 110)
  of LeaderboardStateKind.Loaded:
    var y = 50'i32
    gfx.setDrawMode(kDrawModeNXOR)
    let startIdx = screen.currentLeaderboardPageIdx * LEADERBOARDS_PAGE_SIZE
    let scores = leaderboard.state.scores
    let endIdx = min(startIdx + LEADERBOARDS_PAGE_SIZE, scores.len)
    for i in startIdx ..< endIdx:
      let score = scores[i]
      if score.isCurrentPlayer:
        fillRoundRect(5, y - 2, LCD_COLUMNS - 10, 24, 4, kColorBlack)
      gfx.drawTextAligned($score.rank, 65, y, kTextAlignmentRight)
      gfx.drawText(score.player, 80, y)
      gfx.drawText(score.timeString, 290, y)
      y += 24
    gfx.setDrawMode(kDrawModeCopy)

    gfx.setFont(getOrLoadFont(FontId.Roobert10Bold))
    if scores.len > LEADERBOARDS_PAGE_SIZE:
      gfx.drawTextAligned(
        fmt"⬅️{screen.currentLeaderboardPageIdx + 1} of {scores.high div LEADERBOARDS_PAGE_SIZE + 1}➡️",
        200, 180
      )
  
  gfx.setFont(getOrLoadFont(FontId.Roobert10Bold))
  gfx.drawTextAligned("⬆️⬇️ Track | Ⓑ Back", 200, 220)
  
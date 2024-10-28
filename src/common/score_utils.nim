import std/bitops
import common/shared_types
import common/utils

const
  SCOREBOARDS_MAX_SCORE = 1_000_000

proc calculateScore*(gameResult: GameResult): uint32 =
  let timeScore = SCOREBOARDS_MAX_SCORE - gameResult.time
  let starScore = if gameResult.starCollected: 1 else: 0
  let score = timeScore + starScore
  return score.uint32

proc scoreToTimeString*(score: uint32): string =
  let timeMaskedScore = score div 20 * 20
  let time = (SCOREBOARDS_MAX_SCORE - timeMaskedScore).int32
  return formatTime(time)
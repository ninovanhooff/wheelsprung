import common/shared_types
import common/utils

const
  SCOREBOARDS_MAX_SCORE = 1_000_000

# At a frame time of 20 ms, the score is floored to the nearest 20 ms
# Of the remaing 19 values, 16 ( 0 .. 15) can be used as a 
# raw value or bitmask to store additional information like stars collected

proc calculateScore*(gameResult: GameResult): uint32 =
  let timeScore = SCOREBOARDS_MAX_SCORE - gameResult.time
  let starScore = if gameResult.starCollected: 1 else: 0
  let score = timeScore + starScore
  return score.uint32

proc scoreToTimeString*(score: uint32): string =
  # Floor the score to frame time increments
  let timeMaskedScore = score div NOMINAL_FRAME_TIME_MILLIS * NOMINAL_FRAME_TIME_MILLIS
  let time = (SCOREBOARDS_MAX_SCORE - timeMaskedScore).int32
  return formatTime(time)
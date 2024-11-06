{.push raises:[].}
import std/options
import common/shared_types
import common/utils

const
  SCOREBOARDS_MAX_SCORE* = 1_000_000'u32

# At a frame time of 20 ms, the score is floored to the nearest 20 ms
# Of the remaing 19 values, 16 ( 0 .. 15) can be used as a 
# raw value or bitmask to store additional information like stars collected

proc calculateScore*(levelProgress: LevelProgress): uint32 =
  if levelProgress.bestTime.isNone:
    print "calculateScore: bestTime is None"
    return 0

  if levelProgress.signature.isNone:
    print "calculateScore: signature is None"
    return 0
    
  let timeScore = SCOREBOARDS_MAX_SCORE - levelProgress.bestTime.get().uint32
  let starScore: uint32 = if levelProgress.hasCollectedStar: 1 else: 0
  let score = timeScore + starScore
  return score

proc scoreToTime*(score: uint32, maxScore: uint32 = SCOREBOARDS_MAX_SCORE): Milliseconds =
  if score > maxScore:
    print "scoreToTimeString: score is greater than maxValue", score, maxScore
    return -1
    
  # Floor the score to frame time increments
  let timeMaskedScore = score div NOMINAL_FRAME_TIME_MILLIS * NOMINAL_FRAME_TIME_MILLIS
  return (maxScore - timeMaskedScore).Milliseconds

proc scoreToTimeString*(score: uint32, maxScore: uint32 = SCOREBOARDS_MAX_SCORE): string =
  let time = scoreToTime(score, maxScore)
  if time < 0:
    return "invalid score"
  return formatTime(time)
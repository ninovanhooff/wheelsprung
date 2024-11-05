{.push raises: [].}

import std/tables
import std/options
import common/shared_types
import common/score_utils
import common/utils
import common/integrity
import level_meta/level_data
import data_store/user_profile
import scoreboards/scoreboards_service

proc submitScoreToScoreboard(progress: LevelProgress) =
  if progress.signature.isNone:
    print "Not submitting levelprogress to Scoreboards. Signature is None"
    return

  let boardId = getLevelMeta(progress.levelId).scoreboardId
  if boardId.len == 0:
    print "Not submitting levelprogress to Scoreboards. No scoreboardId"
    return

  let score = progress.calculateScore()
  submitScore(boardId, score)

  # get all official levels which have a scoreboardId and sum the scores
  var totalScore = 0'u32
  for (path, levelMeta) in officialLevels.pairs:
    if levelMeta.scoreboardId.len > 0:
      let levelScore = getLevelProgress(path).calculateScore()
      if levelScore <= 0:
        print "Not submitting total score because no score for", levelMeta.scoreboardId
        return
      totalScore += levelScore
  submitLeaderboardScore(totalScore)

proc updateLevelProgress*(gameResult: GameResult, save: bool) =
  let id = gameResult.levelId

  case gameResult.resultType
    of GameResultType.GameOver:
      return
    of GameResultType.LevelComplete:
      discard # Continue to update progress
  
  var progress: LevelProgress = getLevelProgress(id)
  let bestTime = progress.bestTime.get(Milliseconds.high)
  if gameResult.time < bestTime :
    print ("New best time", gameResult.time, "for level", id)
    progress.bestTime = some(gameResult.time)

  if gameResult.starCollected:
    print ("Collected star for level", id)
    progress.hasCollectedStar = true

  let levelMeta = officialLevels.getOrDefault(id, nil)
  # only official levels need a content hash
  if levelMeta == nil or levelMeta.contentHash == gameResult.levelHash:
    progress.sign()
    submitScoreToScoreboard(progress)
  else:
    print "WARN Level content hash mismatch for level", id
    progress.signature = none(string)
  id.setLevelProgress(progress)

  if save:
    saveSaveSlot()

proc persistGameResult*(gameResult: GameResult) =
  print "PERSSISTING GAME RESULT"
  try:
    updateLevelProgress(gameResult, save=true)
  except:
    print("Failed to persist game result", getCurrentExceptionMsg())
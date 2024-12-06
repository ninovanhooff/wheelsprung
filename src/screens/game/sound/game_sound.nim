import std/random
import common/[utils, audio_utils]
import cache/sound_cache
import playdate/api
## Non-bike sounds, such as win and collision sounds

var
  finishPlayer: SamplePlayer
  coinPlayer: SamplePlayer
  starPlayer: SamplePlayer
  finishUnlockPlayer: SamplePlayer
  collisionPlayers: seq[SamplePlayer]
  fallPlayers: seq[SamplePlayer]

proc initGameSound*() =
  if finishPlayer != nil: return # already initialized

  ## Load the sounds
  try:
    for i in 1..2:
      collisionPlayers.add(getOrLoadSamplePlayer("/audio/collision/collision-0" & $i))
    for i in 1..2:
      fallPlayers.add(getOrLoadSamplePlayer("/audio/fall/fall-0" & $i))

  except:
    quit(getCurrentExceptionMsg(), 1)

proc playFinishSound*() =
  if finishPlayer == nil:
    finishPlayer = getOrLoadSamplePlayer(SampleId.Finish)
  finishPlayer.playVariation()

proc playCoinSound*(coinProgress: float32) =
  ## coinProgress the fraction of coins collected
  if coinProgress < 1.0f:
    if coinPlayer == nil:
      coinPlayer = getOrLoadSamplePlayer(SampleId.Coin)
    coinPlayer.play(1, lerp(0.9, 1.1, coinProgress))
  else:
    if finishUnlockPlayer == nil:
      finishUnlockPlayer = getOrLoadSamplePlayer(SampleId.FinishUnlock)
    finishUnlockPlayer.playVariation()

proc playStarSound*() =
  if starPlayer == nil:
    starPlayer = getOrLoadSamplePlayer(SampleId.Star)
  starPlayer.playVariation()


proc playCollisionSound*() =
  collisionPlayers[rand(collisionPlayers.high)].playVariation()

proc playScreamSound*() =
  fallPlayers[rand(fallPlayers.high)].playVariation()

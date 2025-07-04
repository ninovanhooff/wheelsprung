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
  if collisionPlayers.len > 0: return # already initialized

  ## Load the sounds
  try:
    collisionPlayers.add(getOrLoadSamplePlayer(SampleId.Collision1))
    collisionPlayers.add(getOrLoadSamplePlayer(SampleId.Collision2))
    collisionPlayers.add(getOrLoadSamplePlayer(SampleId.Collision3))
    collisionPlayers.add(getOrLoadSamplePlayer(SampleId.Collision4))
    collisionPlayers.add(getOrLoadSamplePlayer(SampleId.Collision5))
    collisionPlayers.add(getOrLoadSamplePlayer(SampleId.Collision6))
    collisionPlayers.add(getOrLoadSamplePlayer(SampleId.SquirrelSqueak1))
    fallPlayers.add(getOrLoadSamplePlayer(SampleId.Fall1))
    fallPlayers.add(getOrLoadSamplePlayer(SampleId.Fall2))

  except:
    quit(getCurrentExceptionMsg(), 1)

proc playFinishSound*() =
  if finishPlayer == nil:
    finishPlayer = getOrLoadSamplePlayer(SampleId.Finish)
  finishPlayer.play()

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

proc playFallSound*() =
  fallPlayers[rand(fallPlayers.high)].playVariation()

import std/random
import utils, audio_utils
import playdate/api
## Non-bike sounds, such as win and collision sounds

var
  finishPlayer: SamplePlayer
  coinPlayer: SamplePlayer
  starPlayer: SamplePlayer
  finishUnlockPlayer: SamplePlayer
  collisionPlayers: seq[SamplePlayer]
  screamPlayers: seq[SamplePlayer]

proc initGameSound*() =
  if finishPlayer != nil: return # already initialized

  ## Load the sounds
  try:
    finishPlayer = playdate.sound.newSamplePlayer("/audio/finish/finish")
    coinPlayer = playdate.sound.newSamplePlayer("/audio/pickup/coin")
    starPlayer = playdate.sound.newSamplePlayer("/audio/pickup/star")
    finishUnlockPlayer = playdate.sound.newSamplePlayer("/audio/finish/finish_unlock")
    for i in 1..9:
      collisionPlayers.add(playdate.sound.newSamplePlayer("/audio/collision/collision-0" & $i))
    for i in 1..3:
      screamPlayers.add(playdate.sound.newSamplePlayer("/audio/scream/wilhelm_scream-0" & $i))

  except:
    quit(getCurrentExceptionMsg(), 1)

proc playFinishSound*() =
  finishPlayer.playVariation()

proc playCoinSound*(coinProgress: float32) =
  ## coinProgress the fraction of coins collected
  if coinProgress < 1.0f:
    coinPlayer.play(1, lerp(0.9, 1.1, coinProgress))
  else:
    finishUnlockPlayer.playVariation()

proc playStarSound*() =
  starPlayer.playVariation()


proc playCollisionSound*() =
  collisionPlayers[rand(collisionPlayers.high)].playVariation()

proc playScreamSound*() =
  screamPlayers[rand(screamPlayers.high)].playVariation()

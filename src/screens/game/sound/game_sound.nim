import std/random
import audio_utils
import playdate/api
## Non-bike sounds, such as win and collision sounds

var
  finishPlayer: SamplePlayer
  coinPlayer: SamplePlayer
  collisionPlayers: seq[SamplePlayer]

proc initGameSound*() =
  ## Load the sounds
  try:
    finishPlayer = playdate.sound.newSamplePlayer("/audio/finish/finish")
    coinPlayer = playdate.sound.newSamplePlayer("/audio/pickup/coin")
    for i in 1..9:
      collisionPlayers.add(playdate.sound.newSamplePlayer("/audio/collision/collision-0" & $i))

  except:
    quit(getCurrentExceptionMsg(), 1)

proc playFinishSound*() =
  finishPlayer.playVariation()

proc playCoinSound*() =
  coinPlayer.playVariation()

proc playCollisionSound*() =
  collisionPlayers[rand(collisionPlayers.high)].playVariation()
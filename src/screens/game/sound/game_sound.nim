import std/random
import common/[utils, audio_utils]
import playdate/api
import globals
## Non-bike sounds, such as win and collision sounds

var
  finishPlayers: seq[SamplePlayer]
  starPlayers: seq[SamplePlayer]
  finishUnlockPlayer: SamplePlayer
  collisionPlayers: seq[SamplePlayer]
  fallPlayers: seq[SamplePlayer]
  coinPlayers: seq[SamplePlayer]

proc initGameSound*() =
  if finishPlayers.len > 0: return # already initialized

  ## Load the sounds
  try:
    for i in 1..5:
      finishPlayers.add(playdate.sound.newSamplePlayer("/audio/finish/finish" & $i))

    finishUnlockPlayer = playdate.sound.newSamplePlayer("/audio/finish/finish_unlock")
    for i in 1..6:
      collisionPlayers.add(playdate.sound.newSamplePlayer("/audio/collision/collision" & $i))
    for i in 1..4:
      fallPlayers.add(playdate.sound.newSamplePlayer("/audio/fall/fall" & $i))
    for i in 1..6:
      coinPlayers.add(playdate.sound.newSamplePlayer("/audio/pickup/pickup" & $i))
    for i in 1..2:
      starPlayers.add(playdate.sound.newSamplePlayer("/audio/pickup/acorn" & $i))

  except:
    quit(getCurrentExceptionMsg(), 1)

proc playFinishSound*() =
  finishPlayers[debugSoundIdx mod finishPlayers.len].playVariation()

proc playCoinSound*(coinProgress: float32) =
  ## coinProgress the fraction of coins collected
  if coinProgress < 1.0f:
    coinPlayers[debugSoundIdx mod coinPlayers.len].play(1, lerp(0.9, 1.1, coinProgress))
  else:
    finishUnlockPlayer.playVariation()

proc playStarSound*() =
  starPlayers[debugSoundIdx mod starPlayers.len].playVariation()


proc playCollisionSound*() =
  collisionPlayers[debugSoundIdx mod collisionPlayers.len].playVariation()

proc playFallSound*() =
  fallPlayers[debugSoundIdx mod fallPlayers.len].playVariation()

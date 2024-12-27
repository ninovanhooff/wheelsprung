import playdate/api
import common/utils

type
  FadingSamplePlayer* = ref object of RootObj
    samplePlayer: SamplePlayer
    targetVolume*: float32
    lerpSpeed: float32

proc newFadingSamplePlayer*(samplePlayer: SamplePlayer, lerpSpeed: float32 = 0.1f): FadingSamplePlayer =
  FadingSamplePlayer(
    samplePlayer: samplePlayer, 
    targetVolume: 1f, 
    lerpSpeed: lerpSpeed
  )

proc isPlaying*(player: FadingSamplePlayer): bool =
  player.samplePlayer.isPlaying()

proc fadeIn*(player: FadingSamplePlayer, targetVolume: float32 = 1f) =
  player.targetVolume = targetVolume
  if not player.isPlaying:
    player.samplePlayer.play(0, 1f)

proc fadeOut*(player: FadingSamplePlayer) =
  player.targetVolume = 0f

proc stop*(player: FadingSamplePlayer) =
  player.samplePlayer.stop()

proc rate*(player: FadingSamplePlayer): float32 =
  player.samplePlayer.rate

proc `rate=`*(player: FadingSamplePlayer, value: float32) =
  player.samplePlayer.rate = value

proc update*(player: FadingSamplePlayer) =
  if not player.isPlaying(): return

  player.samplePlayer.volume = lerp(player.samplePlayer.volume.left, player.targetVolume, player.lerpSpeed)
  print("volume: ", player.samplePlayer.volume.left)
  if player.targetVolume < 0.01f and player.samplePlayer.volume.left < 0.01f:
    print("stopping")
    player.samplePlayer.stop()
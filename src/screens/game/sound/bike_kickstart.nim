import playdate/api
import utils, audio_utils
import shared_types
import screens/game/game_types

const 
  sampleRate = 44100
  kickStartFootDownEndSample: int32 = (sampleRate * 0.840.Seconds).int32

var
  isInitialized: bool = false
  kickstartPlayer: SamplePlayer
  comeOnPlayer: SamplePlayer

proc initBikeKickStart*() =
  try:
    kickstartPlayer = playdate.sound.newSamplePlayer("/audio/kickstart/kickstart_success.wav")
    comeOnPlayer = playdate.sound.newSamplePlayer("/audio/lickstart/come_on.wav")
    isInitialized = true
  except:
    print(getCurrentExceptionMsg())

proc updateBikeKickStart*(state: GameState) =
  if not isInitialized:
    initBikeKickStart()

  if not kickstartPlayer.isPlaying and abs(playdate.system.getCrankChange()) > 2.0:
    kickstartPlayer.setPlayRange(0, kickStartFootDownEndSample)
    kickstartPlayer.playVariation()
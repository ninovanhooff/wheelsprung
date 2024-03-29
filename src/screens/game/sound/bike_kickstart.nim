import playdate/api
import sugar
import utils, audio_utils
import shared_types
import screens/game/game_types
import bike_engine

const 
  sampleRate = 44100
  kickStartFootDownEndSample: int32 = (sampleRate * 0.840.Seconds).int32
  kickstartSuccessEndSample: int32 = int32.high # play the whole sample

var
  isInitialized: bool = false
  kickstartPlayer: SamplePlayer
  comeOnPlayer: SamplePlayer

proc initBikeKickStart*() =
  try:
    kickstartPlayer = playdate.sound.newSamplePlayer("/audio/kickstart/kickstart_success.wav")
    kickstartPlayer.volume = 0.3 # todo deduplicate with bike_engine
    comeOnPlayer = playdate.sound.newSamplePlayer("/audio/kickstart/kickstart_come_on.wav")
    isInitialized = true
  except:
    print(getCurrentExceptionMsg())

proc updateBikeKickStart*(state: GameState) =
  if not isInitialized:
    initBikeKickStart()

  if not kickstartPlayer.isPlaying and abs(playdate.system.getCrankChange()) > 2.0:
    kickstartPlayer.setFinishCallback((_: pointer) => comeOnPlayer.playVariation())
    kickstartPlayer.setPlayRange(0, kickStartFootDownEndSample)
    kickstartPlayer.playVariation()
  
  print("Crank change: ", playdate.system.getCrankChange())
  if kickstartPlayer.isPlaying and abs(playdate.system.getCrankChange()) > 10.0:
    kickstartPlayer.setFinishCallback(nil)
    kickstartPlayer.setPlayRange(0, kickstartSuccessEndSample)
    # kickstartPlayer.setFinishCallback((_: pointer) => startBikeEngine())

  if kickstartPlayer.isPlaying and kickstartPlayer.offset > 1.9f:
    # nearly at the end of the kickstart sound.
    # since gapless playback is hard, start the engine now
    startBikeEngine()
  
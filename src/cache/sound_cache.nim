{.push raises: [].}
import tables
import playdate/api
import common/utils

template snd*: untyped = playdate.sound


type 
  # a table mapping sound path to AudioSample
  AudioSampleCache = TableRef[string, AudioSample]

  SampleId* {.pure.} = enum
    Finish = "/audio/finish/finish"
    FinishUnlock = "/audio/finish/finish_unlock"
    Coin = "/audio/pickup/coin"
    Star = "/audio/pickup/star"
    Collision1 = "/audio/collision/collision-01"
    Collision2 = "/audio/collision/collision-02"
    Fall1 = "/audio/fall/fall-01"
    Fall2 = "/audio/fall/fall-02"
    BikeSqueak = "/audio/suspension/suspension_contract_adpcm"
    BikeThud1 = "/audio/thud/thud_1"
    BikeThud2 = "/audio/thud/thud_2"
    BikeThud3 = "/audio/thud/thud_3"


# global singleton
let audioSampleCache = AudioSampleCache()

proc getOrLoadSample(path: string): AudioSample =
  try:
    if not audioSampleCache.hasKey(path):
      markStartTime()
      audioSampleCache[path] = snd.newAudioSample(path)
      printT("LOAD Sample: ", path)
    
    return audioSampleCache[path]
  except Exception:
    playdate.system.error("FATAL: " & getCurrentExceptionMsg())

proc getOrLoadSample*(id: SampleId): AudioSample =
  return getOrLoadSample($id)

proc getOrLoadSamplePlayer*(path: string): SamplePlayer =
  result = snd.newSamplePlayer()
  result.sample= getOrLoadSample(path)

proc getOrLoadSamplePlayer*(id: SampleId): SamplePlayer =
  return getOrLoadSamplePlayer($id)

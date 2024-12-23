{.push raises: [].}
import tables
import playdate/api
import common/utils

template snd*: untyped = playdate.sound


type 
  # a table mapping sound path to AudioSample
  AudioSampleCache = TableRef[SampleId, AudioSample]

  SampleId* {.pure.} = enum
    BikeEngineIdle = "/audio/engine/1300rpm_idle"
    BikeEngineThrottle = "/audio/engine/1700rpm_throttle"
    BowlingBallRolling = "/audio/dynamic_objects/bowling_ball_rolling"
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
    BikeCollision1 = "/audio/collision/collision-01"
    BikeCollision2 = "/audio/collision/collision-02"
    BikeFall1 = "/audio/fall/fall-01"
    BikeFall2 = "/audio/fall/fall-02"
    GravityUp = "/audio/gravity/gravity_up"
    GravityDown = "/audio/gravity/gravity_down"
    SelectPrevious = "/audio/menu/select_previous"
    SelectNext = "/audio/menu/select_next"
    Confirm = "/audio/menu/confirm"
    Bumper = "/audio/menu/bumper"

# global singleton
let audioSampleCache = AudioSampleCache()

proc getOrLoadSample*(id: SampleId): AudioSample =
  try:
    if not audioSampleCache.hasKey(id):
      markStartTime()
      audioSampleCache[id] = snd.newAudioSample($id)
      printT("LOAD Sample: ", id)
    
    return audioSampleCache[id]
  except Exception:
    playdate.system.error("FATAL: " & getCurrentExceptionMsg())

proc getOrLoadSamplePlayer*(id: SampleId): SamplePlayer =
  result = snd.newSamplePlayer()
  result.sample= getOrLoadSample(id)

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
    BowlingBallImpact = "/audio/dynamic_objects/bowling_ball_impact"
    MarbleRolling = "/audio/dynamic_objects/marble_rolling"
    MarbleImpact = "/audio/dynamic_objects/marble_impact"
    TennisBallImpact = "/audio/dynamic_objects/tennis_ball_impact"
    Die5Impact = "/audio/dynamic_objects/die5_impact"
    TallBookImpact = "/audio/dynamic_objects/tall_book_impact"
    TallPlankImpact = "/audio/dynamic_objects/tall_plank_impact"
    Finish = "/audio/finish/finish"
    FinishUnlock = "/audio/finish/finish_unlock"
    Coin = "/audio/pickup/coin"
    Star = "/audio/pickup/star"
    Collision1 = "/audio/collision/collision-01"
    Collision2 = "/audio/collision/collision-02"
    Collision3 = "/audio/collision/collision-03"
    Collision4 = "/audio/collision/collision-04"
    Collision5 = "/audio/collision/collision-05"
    Collision6 = "/audio/collision/collision-06"
    Fall1 = "/audio/fall/fall-01"
    Fall2 = "/audio/fall/fall-02"
    BikeSqueak = "/audio/suspension/suspension_contract_adpcm"
    BikeThud1 = "/audio/thud/thud_1"
    BikeThud2 = "/audio/thud/thud_2"
    BikeThud3 = "/audio/thud/thud_3"
    BikeFall1 = "/audio/fall/fall-01"
    BikeFall2 = "/audio/fall/fall-02"
    GravityUp = "/audio/gravity/gravity_up"
    GravityDown = "/audio/gravity/gravity_down"
    SelectPrevious = "/audio/menu/select_previous"
    SelectNext = "/audio/menu/select_next"
    Confirm = "/audio/menu/confirm"
    Cancel = "/audio/menu/cancel"
    SquirrelSqueak1 = "/audio/squirrel/squirrel-squeak-01"

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

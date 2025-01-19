import cache/bitmap_cache
import cache/bitmaptable_cache
import cache/font_cache
import cache/sound_cache
import common/shared_types
import common/utils
import scoreboards/scoreboards_service

type
  PreloadJobType {.pure.} = enum
    BitmapTable
    Font
    Bitmap
    SoundSample
    Scoreboards
  PreloadJob* = ref object
    timeCost: Seconds
    case jobType*: PreloadJobType
    of BitmapTable:
      bitmapTableId*: BitmapTableId
    of Bitmap:
      bitmapId*: BitmapId
    of Font:
      fontId*: FontId
    of SoundSample:
      sampleId*: SampleId
    of Scoreboards:
      discard

var jobs: seq[PreloadJob] = @[
  # order items lowest to highest prio since we will pop from the end
  PreloadJob(timeCost: 0.014.Seconds, jobType: PreloadJobType.SoundSample, sampleId: SampleId.Bumper),
  PreloadJob(timeCost: 0.013.Seconds, jobType: PreloadJobType.SoundSample, sampleId: SampleId.Confirm),
  PreloadJob(timeCost: 0.013.Seconds, jobType: PreloadJobType.SoundSample, sampleId: SampleId.SelectNext),
  PreloadJob(timeCost: 0.013.Seconds, jobType: PreloadJobType.SoundSample, sampleId: SampleId.SelectPrevious),  
  PreloadJob(timeCost: 0.013.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.LevelStatus),
  PreloadJob(timeCost: 0.009.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.Marble),
  PreloadJob(timeCost: 0.016.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.TennisBall),
  PreloadJob(timeCost: 0.007.Seconds, jobType: PreloadJobType.SoundSample, sampleId: SampleId.TennisBallImpact),
  PreloadJob(timeCost: 0.011.Seconds, jobType: PreloadJobType.SoundSample, sampleId: SampleId.BowlingBallRolling),
  PreloadJob(timeCost: 0.011.Seconds, jobType: PreloadJobType.SoundSample, sampleId: SampleId.MarbleRolling),
  PreloadJob(timeCost: 0.007.Seconds, jobType: PreloadJobType.SoundSample, sampleId: SampleId.BowlingBallImpact),
  PreloadJob(timeCost: 0.007.Seconds, jobType: PreloadJobType.SoundSample, sampleId: SampleId.MarbleImpact),
  PreloadJob(timeCost: 0.011.Seconds, jobType: PreloadJobType.Bitmap, bitmapId: BitmapId.Acorn),
  PreloadJob(timeCost: 0.006.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.PickupHighlight),
  PreloadJob(timeCost: 0.021.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.ReadyGo),
  PreloadJob(timeCost: 0.013.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.BikeGhostWheel),
  PreloadJob(timeCost: 0.013.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.BikeWheel),
  PreloadJob(timeCost: 0.013.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.RiderTorso),
  PreloadJob(timeCost: 0.013.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.RiderGhostHead),
  PreloadJob(timeCost: 0.013.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.RiderUpperArm),
  PreloadJob(timeCost: 0.013.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.Killer),
  PreloadJob(timeCost: 0.011.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.Flag),
  PreloadJob(timeCost: 0.013.Seconds, jobType: PreloadJobType.Font, fontId: FontId.NontendoBold),
  PreloadJob(timeCost: 0.012.Seconds, jobType: PreloadJobType.Font, fontId: FontId.M6X11),
  PreloadJob(timeCost: 0.008.Seconds, jobType: PreloadJobType.SoundSample, sampleId: SampleId.Fall1),
  PreloadJob(timeCost: 0.010.Seconds, jobType: PreloadJobType.SoundSample, sampleId: SampleId.Fall2),
  PreloadJob(timeCost: 0.008.Seconds, jobType: PreloadJobType.SoundSample, sampleId: SampleId.Collision1),
  PreloadJob(timeCost: 0.006.Seconds, jobType: PreloadJobType.SoundSample, sampleId: SampleId.Collision2),
  PreloadJob(timeCost: 0.006.Seconds, jobType: PreloadJobType.SoundSample, sampleId: SampleId.BikeThud1),
  PreloadJob(timeCost: 0.005.Seconds, jobType: PreloadJobType.SoundSample, sampleId: SampleId.BikeThud2),
  PreloadJob(timeCost: 0.005.Seconds, jobType: PreloadJobType.SoundSample, sampleId: SampleId.BikeThud3),
  PreloadJob(timeCost: 0.005.Seconds, jobType: PreloadJobType.SoundSample, sampleId: SampleId.BikeSqueak),
  PreloadJob(timeCost: 0.022.Seconds, jobType: PreloadJobType.SoundSample, sampleId: SampleId.BikeEngineIdle),
  PreloadJob(timeCost: 0.019.Seconds, jobType: PreloadJobType.SoundSample, sampleId: SampleId.BikeEngineThrottle),
  PreloadJob(timeCost: 0.012.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.RiderUpperLeg),
  PreloadJob(timeCost: 0.012.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.RiderLowerLeg),
  PreloadJob(timeCost: 0.012.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.RiderLowerArm),
  PreloadJob(timeCost: 0.012.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.Trophy),
  PreloadJob(timeCost: 0.012.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.GravityUp),
  PreloadJob(timeCost: 0.012.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.GravityRight),
  PreloadJob(timeCost: 0.012.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.GravityUpRight),
  PreloadJob(timeCost: 0.030.Seconds, jobType: PreloadJobType.SoundSample, sampleId: SampleId.GravityUp),
  PreloadJob(timeCost: 0.033.Seconds, jobType: PreloadJobType.SoundSample, sampleId: SampleId.GravityDown),
  PreloadJob(timeCost: 0.008.Seconds, jobType: PreloadJobType.SoundSample, sampleId: SampleId.Star),
  PreloadJob(timeCost: 0.011.Seconds, jobType: PreloadJobType.SoundSample, sampleId: SampleId.Finish),
  PreloadJob(timeCost: 0.007.Seconds, jobType: PreloadJobType.SoundSample, sampleId: SampleId.FinishUnlock),
  PreloadJob(timeCost: 0.007.Seconds, jobType: PreloadJobType.SoundSample, sampleId: SampleId.Coin),
  PreloadJob(timeCost: 0.011.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.Nuts),
  PreloadJob(timeCost: 0.014.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.RiderHead),
  PreloadJob(timeCost: 0.018.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.RiderTail),
  PreloadJob(timeCost: 0.019.Seconds, jobType: PreloadJobType.Font, fontId: FontId.Roobert10Bold),
  PreloadJob(timeCost: 0.024.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.BikeChassis),
  # PreloadJob(timeCost: 0.005.Seconds, jobType: PreloadJobType.Scoreboards),
]

proc execute(job: PreloadJob) =
  case job.jobType
  of PreloadJobType.Bitmap:
    discard getOrLoadBitmap(job.bitmapId)
  of PreloadJobType.BitmapTable:
    discard getOrLoadBitmapTable(job.bitmapTableId)
  of PreloadJobType.Font:
    discard getOrLoadFont(job.fontId)
  of PreloadJobType.SoundSample:
    discard getOrLoadSample(job.sampleId)
  of PreloadJobType.Scoreboards:
    fetchAllScoreboards()

proc runPreloader*(deadline: Seconds) =
  var currentTime = getElapsedSeconds()
  for idx in countdown(jobs.high, 0):
    let job = jobs[idx]
    if currentTime + job.timeCost <= deadline:
      job.execute()
      jobs.delete(idx)
      currentTime = getElapsedSeconds()
import cache/bitmaptable_cache
import common/shared_types
import scoreboards/scoreboards_service

type
  PreloadJobType {.pure.} = enum
    BitmapTable
    Scoreboards
    # Font
    # Bitmap
  PreloadJob* = ref object
    timeCost: Seconds
    case jobType*: PreloadJobType
    of BitmapTable:
      bitmapTableId*: BitmapTableId
    of Scoreboards:
      discard

var jobs: seq[PreloadJob] = @[
  # order items lowest to highest prio since we will pop from the end
  PreloadJob(timeCost: 0.024.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.BikeChassis),
  PreloadJob(timeCost: 0.018.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.RiderTail),
  PreloadJob(timeCost: 0.014.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.RiderHead),
  PreloadJob(timeCost: 0.013.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.BikeGhostWheel),
  PreloadJob(timeCost: 0.013.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.BikeWheel),
  PreloadJob(timeCost: 0.013.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.RiderTorso),
  PreloadJob(timeCost: 0.013.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.RiderGhostHead),
  PreloadJob(timeCost: 0.013.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.RiderUpperArm),
  PreloadJob(timeCost: 0.013.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.Killer),
  PreloadJob(timeCost: 0.012.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.RiderUpperLeg),
  PreloadJob(timeCost: 0.012.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.RiderLowerLeg),
  PreloadJob(timeCost: 0.012.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.RiderLowerArm),
  PreloadJob(timeCost: 0.012.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.Trophy),
  PreloadJob(timeCost: 0.012.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.GravityUp),
  PreloadJob(timeCost: 0.012.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.GravityRight),
  PreloadJob(timeCost: 0.012.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.GravityUpRight),
  PreloadJob(timeCost: 0.011.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.Nuts),
  PreloadJob(timeCost: 0.005.Seconds, jobType: PreloadJobType.Scoreboards),
]

proc execute(job: PreloadJob) =
  case job.jobType
  of PreloadJobType.BitmapTable:
    discard getOrLoadBitmapTable(job.bitmapTableId)
  of PreloadJobType.Scoreboards:
    fetchAllScoreboards()

proc runPreloader*(seconds: Seconds) =
  if seconds <= 0.Seconds:
    return

  var remainingSeconds = seconds
  for idx in countdown(jobs.high, 0):
    let job = jobs[idx]
    if job.timeCost <= remainingSeconds:
      job.execute()
      jobs.delete(idx)
      remainingSeconds -= job.timeCost
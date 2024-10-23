import cache/bitmaptable_cache
import common/shared_types
import common/utils

type
  PreloadJobType {.pure.} = enum
    BitmapTable
    # Font
    # Bitmap
  PreloadJob* = ref object
    timeCost: Seconds
    case jobType*: PreloadJobType
    of BitmapTable:
      bitmapTableId*: BitmapTableId

var jobs: seq[PreloadJob] = @[
  # order items from highest to low timeCost
  PreloadJob(timeCost: 0.024.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.BikeChassis),
  PreloadJob(timeCost: 0.018.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.RiderTail),
  PreloadJob(timeCost: 0.014.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.RiderHead),
  PreloadJob(timeCost: 0.013.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.BikeGhostWheel),
  PreloadJob(timeCost: 0.013.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.BikeWheel),
  PreloadJob(timeCost: 0.013.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.RiderTorso),
  PreloadJob(timeCost: 0.013.Seconds, jobType: PreloadJobType.BitmapTable, bitmapTableId: BitmapTableId.RiderGhostHead),
]

proc execute(job: PreloadJob) =
  case job.jobType
  of PreloadJobType.BitmapTable:
    discard getOrLoadBitmapTable(job.bitmapTableId)

proc runPreloader*(seconds: Seconds) =
  var remainingSeconds = seconds
  for idx in countdown(jobs.high, 0):
    let job = jobs[idx]
    if job.timeCost <= remainingSeconds:
      print "Preloading: ", job.repr
      job.execute()
      jobs.delete(idx)
      remainingSeconds -= job.timeCost
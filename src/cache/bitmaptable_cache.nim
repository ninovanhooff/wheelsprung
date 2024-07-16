{.push raises: [].}
import tables
import playdate/api
import common/graphics_types
import common/utils

const
  ## Amount of rotation images (angle steps) for sprites which sjhould be freely rotatable
  ## e.g. bike chassis, rider parts, killer, etc.
  imageRotations: int32 = 64'i32

type
  BitmapTableId* {.pure.} = enum
    BikeChassis = "images/bike-chassis"
    BikeGhostWheel = "images/bike-ghost-wheel"
    BikeWheel = "images/bike-wheel"
    RiderTorso = "images/rider/torso"
    RiderGhostHead = "images/rider/ghost-head"
    RiderHead = "images/rider/head"
    RiderUpperArm = "images/rider/upper-arm"
    RiderLowerArm = "images/rider/lower-arm"
    RiderUpperLeg = "images/rider/upper-leg"
    RiderLowerLeg = "images/rider/lower-leg"
    Killer = "images/killer/killer"
    TallBook = "images/dynamic_objects/tall-book"
    Trophy = "images/trophy"
    Flag = "images/flag/flag"
    Gravity = "images/gravity"
    LevelStatus = "images/level_select/level-status"
  BitmapTableCache = TableRef[BitmapTableId, AnnotatedBitmapTable]

# global singleton
let bitmapTableCache = BitmapTableCache()

proc frameCount(id: BitmapTableId): int32 =
  case id
  of BitmapTableId.Trophy: return 2
  of BitmapTableId.Flag: return 46
  of BitmapTableId.Gravity: return 33
  of BitmapTableId.LevelStatus: return 3
  of BitmapTableId.TallBook: return 240
  
  of BitmapTableId.BikeChassis,
    BitmapTableId.BikeGhostWheel,
    BitmapTableId.BikeWheel,
    BitmapTableId.RiderTorso,
    BitmapTableId.RiderGhostHead,
    BitmapTableId.RiderHead,
    BitmapTableId.RiderUpperArm,
    BitmapTableId.RiderLowerArm,
    BitmapTableId.RiderUpperLeg,
    BitmapTableId.RiderLowerLeg,
    BitmapTableId.Killer: return imageRotations
  

proc loadBitmapTable*(id: BitmapTableId): AnnotatedBitmapTable =
  try:
    return newAnnotatedBitmapTable(
      bitmapTable = gfx.newBitmapTable($id),
      frameCount = id.frameCount,
    )
  except KeyError:
    playdate.system.error("BitmapTableId or FrameCount not found for: " & $id)
    return nil
  except IOError:
    playdate.system.error(getCurrentExceptionMsg())
    return nil

proc getOrLoadBitmapTable*(id: BitmapTableId): AnnotatedBitmapTable =
  try:
    return bitmapTableCache.mgetOrPut(id, loadBitmapTable(id))
  except IOError:
    print getCurrentExceptionMsg()


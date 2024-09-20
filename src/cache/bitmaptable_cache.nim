{.push raises: [].}
import tables
import playdate/api
import common/graphics_types
import common/utils

type
  BitmapTableId* {.pure.} = enum
    BikeChassis = "images/bike-chassis"
    BikeGhostWheel = "images/bike-ghost-wheel"
    BikeWheel = "images/bike-wheel"
    RiderTorso = "images/rider/torso"
    RiderGhostHead = "images/rider/ghost-head"
    RiderHead = "images/rider/head"
    RiderTail = "images/rider/tail"
    RiderUpperArm = "images/rider/upper-arm"
    RiderLowerArm = "images/rider/lower-arm"
    RiderUpperLeg = "images/rider/upper-leg"
    RiderLowerLeg = "images/rider/lower-leg"
    Killer = "images/killer/killer"
    TallBook = "images/dynamic_objects/tall-book"
    Trophy = "images/trophy"
    Flag = "images/flag/flag"
    Nuts = "images/nuts"
    Gravity = "images/gravity"
    LevelStatus = "images/level_select/level-status"
    GameResultActionArrows = "images/game_result/action-arrows"
  BitmapTableCache = TableRef[BitmapTableId, AnnotatedBitmapTable]

# global singleton
let bitmapTableCache = BitmapTableCache()

proc loadBitmapTable*(id: BitmapTableId): AnnotatedBitmapTable =
  try:
    let bitmapTable = gfx.newBitmapTable($id)
    return newAnnotatedBitmapTable(
      bitmapTable = bitmapTable,
      frameCount = bitmapTable.getBitmapTableInfo().count.int32,
    )
  except KeyError:
    playdate.system.error("BitmapTableId or FrameCount not found for: " & $id)
    return nil
  except IOError:
    playdate.system.error(getCurrentExceptionMsg())
    return nil

proc getOrLoadBitmapTable*(id: BitmapTableId): AnnotatedBitmapTable =
  try:
    if not bitmapTableCache.hasKey(id):
      bitmapTableCache[id] = loadBitmapTable(id)
    
    return bitmapTableCache[id]
  except Exception:
    print getCurrentExceptionMsg()


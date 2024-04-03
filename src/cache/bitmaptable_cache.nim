{.push raises: [].}
import tables
import playdate/api
import graphics_types
import utils

type
  BitmapTableId* {.pure.} = enum
    Flag = "images/flag/flag"
  BitmapTableCache = TableRef[BitmapTableId, AnnotatedBitmapTable]

let bitmapTableFrameCounts = {Flag: 46'i32}.toTable

# global singleton
let bitmapTableCache = BitmapTableCache()

proc loadBitmapTable*(id: BitmapTableId): AnnotatedBitmapTable =
  try:
    return AnnotatedBitmapTable(
      bitmapTable: gfx.newBitmapTable($id),
      frameCount: bitmapTableFrameCounts[id],
    )
  except KeyError:
    playdate.system.error("BitmapTableId not found: " & $id)
    return nil
  except IOError:
    playdate.system.error(getCurrentExceptionMsg())
    return nil

proc getOrLoadBitmapTable*(id: BitmapTableId): AnnotatedBitmapTable =
  try:
    return bitmapTableCache.mgetOrPut(id, loadBitmapTable(id))
  except IOError:
    print getCurrentExceptionMsg()


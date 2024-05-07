{.push raises: [].}
import tables
import playdate/api
import common/graphics_types

type 
  # a table mapping image path to LCDBitmap
  BitmapCache = TableRef[string, LCDBitmap]

# global singleton
let bitmapCache = BitmapCache()

proc getOrLoadBitmap*(path: string): LCDBitmap =
  try:
    return bitmapCache.mgetOrPut(path, gfx.newBitmap(path))
  except IOError:
    playdate.system.error("FATAL: " & getCurrentExceptionMsg())


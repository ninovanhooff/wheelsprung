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
    if not bitmapCache.hasKey(path):
      bitmapCache[path] = gfx.newBitmap(path)
    
    return bitmapCache[path]
  except Exception:
    playdate.system.error("FATAL: " & getCurrentExceptionMsg())


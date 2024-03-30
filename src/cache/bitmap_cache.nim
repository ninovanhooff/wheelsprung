{.push raises: [].}
import tables
import playdate/api
import graphics_types
import utils

type 
  # a table mapping image path to LCDBitmap
  BitmapCache = TableRef[string, LCDBitmap]

# global singleton
let bitmapCache = BitmapCache()

proc getOrLoadBitmap*(path: string): LCDBitmap =
  try:
    return bitmapCache.mgetOrPut(path, gfx.newBitmap(path))
  except IOError:
    print getCurrentExceptionMsg()


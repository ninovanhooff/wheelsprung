{.push raises: [].}
import tables
import playdate/api
import common/graphics_types
import common/utils

type
  BitmapId* {.pure.} = enum
    Acorn = "images/acorn"
    LevelSelectBgKitchen = "images/level_select/bg-kitchen"
    LevelSelectBgBath = "images/level_select/bg-bath"
    LevelSelectBgBookshelf = "images/level_select/bg-bookshelf"
    LevelSelectBgDesk = "images/level_select/bg-desk"
    LevelSelectBgSpace = "images/level_select/bg-space"
    LevelSelectBgPlants = "images/level_select/bg-plants"

  # a table mapping image path to LCDBitmap
  BitmapCache = TableRef[string, LCDBitmap]

# global singleton
let bitmapCache = BitmapCache()

proc getOrLoadBitmap*(path: string): LCDBitmap =
  try:
    if not bitmapCache.hasKey(path):
      markStartTime()
      bitmapCache[path] = gfx.newBitmap(path)
      printT("LOAD Bitmap: ", path)
    
    return bitmapCache[path]
  except Exception:
    if defined(debug):
      print("Failed to load bitmap: " & getCurrentExceptionMsg())
    else:
      playdate.system.error("FATAL: " & getCurrentExceptionMsg())

proc getOrLoadBitmap*(id: BitmapId): LCDBitmap =
  getOrLoadBitmap($id)

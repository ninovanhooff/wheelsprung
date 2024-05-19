{.push raises: [].}
import tables
import playdate/api
import common/graphics_types

type 
  # a table mapping font path to LCDFont
  FontCache = TableRef[string, LCDFont]

# global singleton
let fontCache = FontCache()

proc getOrLoadFont*(path: string): LCDFont =
  try:
    return fontCache.mgetOrPut(path, gfx.newFont(path))
  except IOError:
    playdate.system.error("FATAL: " & getCurrentExceptionMsg())


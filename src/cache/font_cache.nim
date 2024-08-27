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
    if not fontCache.hasKey(path):
      fontCache[path] = gfx.newFont(path)
    
    return fontCache[path]
  except Exception:
    playdate.system.error("FATAL: " & getCurrentExceptionMsg())

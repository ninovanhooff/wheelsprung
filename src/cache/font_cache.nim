{.push raises: [].}
import tables
import playdate/api
import common/graphics_types
import common/utils

type
  FontId* {.pure.} = enum
    NontendoBold = "fonts/Nontendo-Bold-2x"
    M6X11 = "fonts/m6x11-12"
    Roobert10Bold = "fonts/Roobert-10-Bold"
    Roobert11Medium = "fonts/Roobert-11-Medium"
    Roobert11Bold = "fonts/Roobert-11-Bold"
  # a table mapping font path to LCDFont
  FontCache = TableRef[string, LCDFont]

# global singleton
let fontCache = FontCache()

proc getOrLoadFont*(path: string): LCDFont =
  try:
    if not fontCache.hasKey(path):
      markStartTime()
      fontCache[path] = gfx.newFont(path)
      printT("LOAD Font: ", path)
    
    return fontCache[path]
  except Exception:
    if defined(debug):
      print(getCurrentExceptionMsg())
    else:
      playdate.system.error("FATAL: " & getCurrentExceptionMsg())

proc getOrLoadFont*(id: FontId): LCDFont =
  return getOrLoadFont($id)

{.push raises: [].}
import tables
import playdate/api
import common/graphics_types
import common/utils
import common/lcd_patterns

const
  patternSize = 32

let patternCache = TableRef[LCDPatternId, LCDBitmap]()

proc createBitmap(id: LCDPatternId): LCDBitmap =
  markStartTime()
  let pattern = 
    case id
    of Dot1: patDot1
    of Grid4: patGrid4
    of Gray: patGray
    of GrayTransparent: patGrayTransparent
  result = gfx.newBitmap(patternSize, patternSize, pattern)
  printT("CREATE Bitmap: ", $id)

proc getOrCreateBitmap*(id: LCDPatternId): LCDBitmap =
  try:
    if not patternCache.hasKey(id):
      patternCache[id] = createBitmap(id)
    return patternCache[id]
  except Exception:
    if defined(debug):
      print("Failed to get pattern bitmap: " & getCurrentExceptionMsg())
    else:
      playdate.system.error("FATAL: " & getCurrentExceptionMsg())

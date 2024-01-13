import std/math
import playdate/api
import chipmunk7
import utils

## Amount of rotation images (angle steps) in the table
const imageRotations = 64

proc drawRotated*(table: LCDBitmapTable, center: Vect, angle: float32) =
    ## angle is in radians
    let index = ((normalizeAngle(angle) / TwoPi) * imageRotations).int32 mod imageRotations
    let bitmap = table.getBitmap(index)

    # todo optimize: cache for table
    let x: int32 = (center.x - bitmap.width.float32 / 2f).int32
    let y: int32 = (center.y - bitmap.height.float32 / 2f).int32
    bitmap.draw(x, y, kBitmapUnflipped)

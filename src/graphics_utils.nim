import playdate/api
import chipmunk7
import utils

template gfx*: untyped = playdate.graphics

## Amount of rotation images (angle steps) in the table
const imageRotations = 64

proc drawRotated*(table: LCDBitmapTable, center: Vect, angle: float32, flip: LCDBitmapFlip) =
    ## angle is in radians
    let index = ((normalizeAngle(angle) / TwoPi) * imageRotations).int32 mod imageRotations
    let bitmap = table.getBitmap(index)

    if bitmap == nil:
        return

    # todo optimize: cache for table
    let x: int32 = (center.x - bitmap.width.float32 / 2f).int32
    let y: int32 = (center.y - bitmap.height.float32 / 2f).int32
    bitmap.draw(x, y, flip)

proc drawLineOutlined*(v0: Vect, v1: Vect, width: int32, innerColor: LCDSolidColor) =
    # draw outer line
    gfx.drawLine(
        v0.x.toInt, 
        v0.y.toInt, 
        v1.x.toInt, 
        v1.y.toInt, 
        width, 
        if innerColor == kColorBlack : kColorWhite else: kColorBlack
    )
    # draw inner line
    gfx.drawLine(
        v0.x.toInt, 
        v0.y.toInt, 
        v1.x.toInt, 
        v1.y.toInt, 
        (width/2).int32, 
        innerColor
    )

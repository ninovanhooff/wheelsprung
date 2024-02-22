import playdate/api
import chipmunk7
import std/math
import utils
import graphics_types

template gfx*: untyped = playdate.graphics

const
  displaySize* = v(400.0, 240.0)
  halfDisplaySize*: Vect = displaySize.vmult(0.5)
  ## Amount of rotation images (angle steps) in the table
  imageRotations = 64

proc toVertex*(v: Vect): Vertex = 
  [v.x.round.int32, v.y.round.int32]

proc toVect*(vertex: Vertex): Vect =
  return v(vertex[0].Float, vertex[1].Float)

proc `-`*(a: Vertex, b: Vertex): Vertex = 
  return [a[0] - b[0], a[1] - b[1]]

proc `+`*(a: Vertex, b: Vertex): Vertex =
  return [a[0] + b[0], a[1] + b[1]]

proc drawRotated*(table: LCDBitmapTable, center: Vect, angle: float32, flip: LCDBitmapFlip = kBitmapUnflipped) =
  ## angle is in radians
  let index = ((normalizeAngle(angle) / TwoPi) * imageRotations).int32 mod imageRotations
  let bitmap = table.getBitmap(index)

  if bitmap == nil:
    print "Bitmap is nil for index: " & $index
    return

  # todo optimize: cache for table
  let x: int32 = (center.x - bitmap.width.float * 0.5).round.int32
  let y: int32 = (center.y - bitmap.height.float * 0.5).round.int32
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

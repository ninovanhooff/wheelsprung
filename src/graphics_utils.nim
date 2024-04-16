import playdate/api
import chipmunk7
import std/math
import utils
import graphics_types
import cache/bitmaptable_cache
import random

const
  displaySize* = v(400.0, 240.0)
  halfDisplaySize*: Vect = displaySize.vmult(0.5)

proc toVertex*(v: Vect): Vertex = 
  (v.x.round.int32, v.y.round.int32)

proc toVect*(vertex: Vertex): Vect =
  return v(x = vertex.x.Float, y = vertex.y.Float)

proc `-`*(a: Vertex, b: Vertex): Vertex = 
  return (a[0] - b[0], a[1] - b[1])

proc `+`*(a: Vertex, b: Vertex): Vertex =
  return (a[0] + b[0], a[1] + b[1])

proc drawRotated*(annotatedT: AnnotatedBitmapTable, center: Vect, angle: float32, flip: LCDBitmapFlip = kBitmapUnflipped) {.inline.} =
  ## angle is in radians
  let index: int32 = (((normalizeAngle(angle) / TwoPi) * annotatedT.frameCount.float32).int32)
  # let index = unboundedIndex mod frameCount
  let bitmap = annotatedT.bitmapTable.getBitmap(index)

  if bitmap == nil:
    print "Bitmap is nil for index: " & $index, "angle: " & $angle, "normalizeAngle: " & $normalizeAngle(angle), "equalsToTwoPi: " & $(normalizeAngle(angle) == TwoPi)
    return

  let x: int32 = (center.x.float32 - annotatedT.halfFrameWidth).round.int32
  let y: int32 = (center.y.float32 - annotatedT.halfFrameHeight).round.int32
  bitmap.draw(x, y, flip)

proc fallbackBitmap*(): LCDBitmap = 
  let errorPattern = makeLCDOpaquePattern(0x0, 0x3C, 0x5A, 0x66, 0x66, 0x5A, 0x3C, 0x0)
  gfx.newBitmap(8,8, errorPattern)

proc newAnimation*(bitmapTableId: BitmapTableId, position: Vertex, flip: LCDBitmapFlip, randomStartOffset: bool): Animation =
  let annotatedTable = getOrLoadBitmapTable(bitmapTableId)
  return Animation(
    bitmapTable: annotatedTable.bitmapTable, 
    frameCount: annotatedTable.frameCount,
    position: position,
    flip: flip,
    startOffset: if randomStartOffset: rand(annotatedTable.frameCount).int32 else: 0'i32,
  )

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

proc drawPolyline*(vertices: seq[Vertex], width: int32 = 1, color: LCDColor = kColorBlack) =
  for i in 0..vertices.high-1:
    let v0 = vertices[i]
    let v1 = vertices[i+1]
    gfx.drawLine(v0.x, v0.y, v1.x, v1.y, width, color)

proc fillCircle*(x, y: int32, radius: int32, color: LCDColor = kColorBlack ) {.inline.} =
  gfx.fillEllipse(x - radius,y - radius,radius * 2'i32, radius * 2'i32, 0f, 0f, color);

proc draw*(rect: Rect, color: LCDColor) {.inline.} =
  gfx.drawRect(rect.x, rect.y, rect.width, rect.height, color)

proc fill*(rect: Rect, color: LCDColor) {.inline.} =
  gfx.fillRect(rect.x, rect.y, rect.width, rect.height, color)

proc setScreenClipRect*(rect: Rect) {.inline.} =
  gfx.setClipRect(rect.x, rect.y, rect.width, rect.height)

proc inset*(rect: Rect, left, top, right, bottom: int32): Rect =
  return Rect(
    x: rect.x + left, 
    y: rect.y + top, 
    width: rect.width - left - right, 
    height: rect.height - top - bottom
  )

proc inset*(rect: Rect, x: int32, y: int32): Rect =
  return Rect(
    x: rect.x + x, 
    y: rect.y + y, 
    width: rect.width - x * 2, 
    height: rect.height - y * 2
  )

proc inset*(rect: Rect, size: int32): Rect =
  return Rect(
    x: rect.x + size, 
    y: rect.y + size, 
    width: rect.width - size * 2, 
    height: rect.height - size * 2
  )

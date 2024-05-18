import playdate/api
when defined(DEBUG):
  import common/utils

template gfx*: untyped = playdate.graphics

type
  Vertex* = tuple [x, y: int32]
  Size* = Vertex
  Polygon* = object of RootObj
    vertices*: seq[Vertex]
    fill*: LCDPattern
    bounds*: LCDRect
  Polyline* = object of RootObj
    vertices*: seq[Vertex]
    stroke*: LCDPattern
    thickness*: float32
  Rect* {.requiresInit.} = object of RootObj
    x*, y*, width*, height*: int32

  AnnotatedBitmapTable* = ref object of RootObj
    bitmapTable*: LCDBitmapTable
    frameCount*: int32
    halfFrameWidth*: float32
    halfFrameHeight*: float32

  Asset* = ref object of RootObj
    position*: Vertex
    flip*: LCDBitmapFlip
  Texture* = ref object of Asset
    image*: LCDBitmap
  Animation* = ref object of Asset
    bitmapTable*: LCDBitmapTable
    frameCount*: int32
    startOffset*: int32

when defined(DEBUG):
  proc `=copy`(dest: var Polygon; src: Polygon) =
    # Echo some message when Foo is copied
    print src, " is copied"
    dest = Polygon(vertices: src.vertices, fill: src.fill, bounds: src.bounds)

let
  emptyPolygon*: Polygon = Polygon(vertices: @[], fill: nil)
  emptyPolyline*: Polyline = Polyline(vertices: @[], stroke: nil)

proc bottom*(rect: Rect): int32 =
  result = rect.y + rect.height

proc right*(rect: Rect): int32 =
  result = rect.x + rect.width

proc newTexture*(image: LCDBitmap, position: Vertex, flip: LCDBitmapFlip): Texture =
  result = Texture(image: image, position: position, flip: flip)

proc getBitmap*(annotatedTable: AnnotatedBitmapTable, frame: int32): LCDBitmap {.inline.} =
  result = annotatedTable.bitmapTable.getBitmap(frame)

proc newAnnotatedBitmapTable*(bitmapTable: LCDBitmapTable, frameCount: int32): AnnotatedBitmapTable =
  let firstBitmap = bitmapTable.getBitmap(0)
  result = AnnotatedBitmapTable(
  bitmapTable: bitmapTable,
  frameCount: frameCount,
  halfFrameWidth: firstBitmap.width.float32 * 0.5f,
  halfFrameHeight: firstBitmap.height.float32 * 0.5f
  )

proc newPolyline*(vertices: seq[Vertex], thickness: float32, stroke: LCDPattern = nil): Polyline =
  result = Polyline(vertices: vertices, thickness: thickness, stroke: stroke)

proc newPolygon*(vertices: seq[Vertex], bounds: LCDRect, fill: LCDPattern = nil): Polygon =
  result = Polygon(vertices: vertices, bounds: bounds, fill: fill)

proc newVertex*(x, y: int32): Vertex =
  result = (x: x, y: y)

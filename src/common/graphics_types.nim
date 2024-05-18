import playdate/api
import common/utils
template gfx*: untyped = playdate.graphics

type
  Vertex* = tuple [x, y: int32]
  Size* = Vertex
  Polygon* = object of RootObj
    vertices*: seq[Vertex]
    edgeIndices*: seq[bool]
      ## indices of vertices that also occur in other polygons. Length must match vertices.len
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

const LCD_RECT_ZERO* = makeLCDRect(0, 0, 0, 0)

proc newPolygon*(vertices: seq[Vertex], bounds: LCDRect, fill: LCDPattern = nil, edgeIndices: seq[bool] = @[]): Polygon
  ## forward declaration

when defined(DEBUG):
  proc `=copy`(dest: var Polygon; src: Polygon) =
    # Echo some message when Foo is copied
    print src, " is copied"
    dest = newPolygon(
      vertices = src.vertices,
      bounds = src.bounds,
      edgeIndices = src.edgeIndices,
      fill = src.fill, 
    )


proc newPolygon*(vertices: seq[Vertex], bounds: LCDRect, fill: LCDPattern = nil, edgeIndices: seq[bool] = @[]): Polygon =
  result = Polygon(
    vertices: vertices, 
    edgeIndices: if edgeIndices.len > 0: edgeIndices else: newSeq[bool](vertices.len), 
    bounds: bounds, 
    fill: fill
    # keep up to date with =copy
  )

proc newPolyline*(vertices: seq[Vertex], thickness: float32, stroke: LCDPattern = nil): Polyline =
  result = Polyline(vertices: vertices, thickness: thickness, stroke: stroke)

let
  emptyPolygon*: Polygon = newPolygon(vertices = @[], bounds = LCD_RECT_ZERO, fill = nil)
  emptyPolyline*: Polyline = newPolyline(vertices = @[], thickness = 0, stroke = nil)

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

proc newVertex*(x, y: int32): Vertex =
  result = (x: x, y: y)

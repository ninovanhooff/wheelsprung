import std/options
import playdate/api
import chipmunk7
{. warning[UnusedImport]:off .}
import common/utils
template gfx*: untyped = playdate.graphics

type
  Vertex* = tuple [x, y: int32]
  Size* = Vertex
  Polygon* = object of RootObj
    vertices*: seq[Vertex]
    edgeIndices*: seq[bool]
      ## indices of segments that also occur in other polygons. Length must match vertices.len - 1
    normals*: seq[Vertex]
      ## normals of the edges. Length must match vertices.len - 1
    fill*: LCDPattern
    bounds*: LCDRect
  Polyline* = object of RootObj
    vertices*: seq[Vertex]
    stroke*: LCDPattern
    thickness*: float32
  Rect* {.requiresInit.} = object of RootObj
    x*, y*, width*, height*: int32

  LCDPatternId* {.pure.} = enum
    Dot1
    Grid4
    Gray
    GrayTransparent

  AnnotatedBitmapTable* = ref object of RootObj
    bitmapTable*: LCDBitmapTable
    frameCount*: int32
    frameWidth*: int32
    frameHeight*: int32
    halfFrameWidth*: float32 ## separate property for efficiency, accessed every frame
    halfFrameHeight*: float32

  Asset* = ref object of RootObj
    position*: Vertex
    bounds*: LCDRect
    flip*: LCDBitmapFlip
    stencilPatternId*: Option[LCDPatternId]
  Texture* = ref object of Asset
    image*: LCDBitmap
  Animation* = ref object of Asset
    bitmapTable*: LCDBitmapTable
    frameCount*: int32
    startOffset*: int32
    frameRepeat*: int32
      ## divisor of the frame rate
  
  Camera* = Vect
  CameraState* = object
    camera*: Camera
    camVertex*: Vertex
    viewport*: LCDRect
    frameCounter*: int32

const LCD_RECT_ZERO* = makeLCDRect(0, 0, 0, 0)

proc newPolygon*(vertices: seq[Vertex], bounds: LCDRect, fill: LCDPattern = nil, edgeIndices: seq[bool] = @[]): Polygon
  ## forward declaration

when defined(DEBUG):
  proc `=copy`(dest: var Polygon; src: Polygon) =
    # Echo some message when Foo is copied
    echo "Polygon is copied:", src.bounds
    dest = newPolygon(
      vertices = src.vertices,
      bounds = src.bounds,
      edgeIndices = src.edgeIndices,
      fill = src.fill, 
    )

proc calculateNormals(vertices: seq[Vertex]): seq[Vertex] =
  if vertices.len < 2:
    return @[]

  result = newSeq[Vertex](vertices.len - 1)
  for i in 0 ..< vertices.high:
    let v1 = vertices[i]
    let v2 = vertices[i+1]
    ## https://stackoverflow.com/a/1243676/923557
    let vNormal: Vertex = (x: v2.y - v1.y, y: v1.x - v2.x)
    result[i] = vNormal

proc newPolygon*(vertices: seq[Vertex], bounds: LCDRect, fill: LCDPattern = nil, edgeIndices: seq[bool] = @[]): Polygon =
  result = Polygon(
    vertices: vertices, 
    edgeIndices: if edgeIndices.len > 0: edgeIndices else: newSeq[bool](vertices.len),
    normals: vertices.calculateNormals(),
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
  result = Texture(
    image: image,
    position: position,
    bounds: LCDRect(
      left: position.x, 
      right: position.x + image.width.int32, 
      top: position.y,
      bottom: position.y + image.height.int32,
    ),
    flip: flip
  )

proc getBitmap*(annotatedTable: AnnotatedBitmapTable, frame: int32): LCDBitmap {.inline.} =
  result = annotatedTable.bitmapTable.getBitmap(frame)

proc newAnnotatedBitmapTable*(bitmapTable: LCDBitmapTable, frameCount: int32): AnnotatedBitmapTable =
  let firstBitmap = bitmapTable.getBitmap(0)
  result = AnnotatedBitmapTable(
    bitmapTable: bitmapTable,
    frameCount: frameCount,
    frameWidth: firstBitmap.width.int32,
    frameHeight: firstBitmap.height.int32,
    halfFrameWidth: firstBitmap.width.float32 * 0.5f,
    halfFrameHeight: firstBitmap.height.float32 * 0.5f
  )

proc newVertex*(x, y: int32): Vertex =
  result = (x: x, y: y)

proc newCameraState*(camera: Camera, camVertex: Vertex, viewport: LCDRect, frameCounter: int32): CameraState =
  result = CameraState(
    camera: camera,
    camVertex: camVertex,
    viewport: viewport,
    frameCounter: frameCounter,
  )

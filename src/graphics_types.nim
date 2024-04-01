import playdate/api
template gfx*: untyped = playdate.graphics

type
    Int32x2 = array[2, int32]
    Vertex* = Int32x2
    Polygon* = object of RootObj
        vertices*: seq[Vertex]
        fill*: LCDPattern
    Rect* {.requiresInit.} = object of RootObj
        x*, y*, width*, height*: int32

let
    emptyPolygon*: Polygon = Polygon(vertices: @[], fill: nil)

proc bottom*(rect: Rect): int32 =
    result = rect.y + rect.height

proc right*(rect: Rect): int32 =
    result = rect.x + rect.width

proc newPolygon*(vertices: seq[Vertex], fill: LCDPattern = nil): Polygon =
    result = Polygon(vertices: vertices, fill: fill)
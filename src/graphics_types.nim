type
    Int32x2 = array[2, int32]
    Vertex* = Int32x2
    Polygon* = seq[Vertex]
    Rect* {.requiresInit.} = object of RootObj
        x*, y*, width*, height*: int32

proc bottom*(rect: Rect): int32 =
    result = rect.y + rect.height

proc right*(rect: Rect): int32 =
    result = rect.x + rect.width
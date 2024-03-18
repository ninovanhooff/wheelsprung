type
    Int32x2 = array[2, int32]
    Vertex* = Int32x2
    Polygon* = seq[Vertex]
    Rect* {.requiresInit.} = object of RootObj
        x*, y*, width*, height*: int32

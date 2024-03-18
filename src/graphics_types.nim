type
    Int32x2 = array[2, int32]
    Vertex* = Int32x2
    Polygon* = seq[Vertex]
    Rect* = object
        x*, y*, width*, height*: int32

proc newRect*(x, y, width, height: int32): Rect =
    Rect(x: x, y: y, width: width, height: height)
import playdate/api

template gfx*: untyped = playdate.graphics

type
  Vertex* = tuple [x, y: int32]
  Polygon* = seq[Vertex]
  Rect* {.requiresInit.} = object of RootObj
    x*, y*, width*, height*: int32

  AnnotatedBitmapTable* = ref object of RootObj
    bitmapTable*: LCDBitmapTable
    frameCount*: int32
  
  Asset* = ref object of RootObj
    position*: Vertex
    flip*: LCDBitmapFlip
  Texture* = ref object of Asset
    image*: LCDBitmap
  Animation* = ref object of Asset
    bitmapTable*: LCDBitmapTable
    frameCount*: int32
    startOffset*: int32

proc bottom*(rect: Rect): int32 =
  result = rect.y + rect.height

proc right*(rect: Rect): int32 =
  result = rect.x + rect.width

proc newTexture*(image: LCDBitmap, position: Vertex, flip: LCDBitmapFlip): Texture =
  result = Texture(image: image, position: position, flip: flip)

# proc newAnimationFromAnnotatedTable*(bitmapTable: AnnotatedBitmapTable, position: Vertex, flip: LCDBitmapFlip, startOffset: int32): Animation {.inline.} =
#   result = Animation(
#     bitmapTable: bitmapTable.bitmapTable, frameCount: bitmapTable.frameCount, 
#     startOffset: startOffset,
#     position: position, flip: flip
#   )

{.push raises: [].}

import playdate/api
import chipmunk7
import std/math
import std/options
import common/utils
import common/graphics_types
export graphics_types
import cache/bitmaptable_cache
import cache/stencil_image_cache
import random

const
  displaySize* = v(400.0, 240.0)
  halfDisplaySize*: Vect = displaySize.vmult(0.5)

proc toVertex*(v: Vect): Vertex {.inline.} = 
  (v.x.round.int32, v.y.round.int32)

proc toVect*(vertex: Vertex): Vect {.inline.} =
  return v(x = vertex.x.Float, y = vertex.y.Float)

proc `-`*(a: Vertex, b: Vertex): Vertex {.inline.} = 
  return (a[0] - b[0], a[1] - b[1])

proc `+`*(a: Vertex, b: Vertex): Vertex {.inline.} =
  return (a[0] + b[0], a[1] + b[1])

proc `div`*(a: Vertex, b: int32): Vertex {.inline.} =
  return (x: a.x div b, y: a.y div b)

proc dotVertex*(v1: Vertex, v2: Vertex): int32 {.inline.} =
  ## 2D Dot product of two vectors
  return v1.x * v2.x + v1.y * v2.y

proc fallbackBitmap*(): LCDBitmap = 
  let errorPattern = makeLCDOpaquePattern(0x0, 0x3C, 0x5A, 0x66, 0x66, 0x5A, 0x3C, 0x0)
  gfx.newBitmap(8,8, errorPattern)

# LCDRect

proc encapsulate*(lcdRect: var LCDRect, vertex: Vertex) =
  ## Stretch the lcdRect to include the vertex
  lcdRect.left = min(lcdRect.left, vertex.x)
  lcdRect.right = max(lcdRect.right, vertex.x)
  lcdRect.top = min(lcdRect.top, vertex.y)
  lcdRect.bottom = max(lcdRect.bottom, vertex.y)

proc contains*(lcdRect: LCDRect, vertex: Vertex): bool =
  return vertex.x >= lcdRect.left and vertex.x <= lcdRect.right and vertex.y >= lcdRect.top and vertex.y <= lcdRect.bottom

proc intersects*(lcdRect: LCDRect, other: LCDRect): bool =
  return lcdRect.left <= other.right and lcdRect.right >= other.left and lcdRect.top <= other.bottom and lcdRect.bottom >= other.top

proc offsetBy*(lcdRect: LCDRect, offset: Vertex): LCDRect =
  return LCDRect(
    left: lcdRect.left + offset.x,
    right: lcdRect.right + offset.x,
    top: lcdRect.top + offset.y,
    bottom: lcdRect.bottom + offset.y
  )

proc offsetScreenRect*(vertex: Vertex): LCDRect {.inline.} =
  return LCD_SCREEN_RECT.offsetBy(vertex)

proc drawRotated*(annotatedT: AnnotatedBitmapTable, center: Vect, angle: float32, flip: LCDBitmapFlip = kBitmapUnflipped) {.inline.} =
  ## angle is in radians
  let frameCount = annotatedT.frameCount
  var index: int32 = ((normalizeAngle(angle) / TwoPi) * frameCount.float32).roundToNearestInt
  if index == frameCount: index = 0
  let bitmap: LCDBitmap = annotatedT.bitmapTable.getBitmap(index)

  if bitmap.isNil:
    print "Bitmap is nil for index: " & $index, "angle: " & $angle, "normalizeAngle: " & $normalizeAngle(angle), "equalsToTwoPi: " & $(normalizeAngle(angle) == TwoPi)
    return

  let x: int32 = (center.x.float32 - annotatedT.halfFrameWidth).round.int32
  let y: int32 = (center.y.float32 - annotatedT.halfFrameHeight).round.int32
  bitmap.draw(x, y, flip)

method getBitmap(asset: Asset, frameCounter: int32): LCDBitmap {.base.} =
  print("getImage not implemented for: ", repr(asset))
  return fallbackBitmap()

method getBitmap(asset: Texture, frameCounter: int32): LCDBitmap =
  return asset.image

method getBitmap(asset: Animation, frameCounter: int32): LCDBitmap =
  if asset.frameRepeat < 1:
    ## no animation
    return asset.bitmapTable.getBitmap(asset.startOffset)
  let frameIdx = (asset.startOffset + frameCounter div asset.frameRepeat) mod asset.frameCount
  return asset.bitmapTable.getBitmap(frameIdx)

proc setStencilPattern*(patternId: LCDPatternId) {.inline.} =
  gfx.setStencilImage(patternId.getOrCreateBitmap(), true)

proc drawAsset*(asset: Asset, camState: CameraState) =
  if asset.stencilPatternId.isSome:
    setStencilPattern(asset.stencilPatternId.get)

  if asset.bounds.intersects(camState.viewport):
    let assetScreenPos = asset.position - camState.camVertex
    asset.getBitmap(camState.frameCounter).draw(assetScreenPos[0], assetScreenPos[1], asset.flip)

  if asset.stencilPatternId.isSome:
    gfx.setStencilImage(LCD_BITMAP_NONE)

proc newAnimation*(bitmapTable: LCDBitmapTable, position: Vertex, flip: LCDBitmapFlip, startOffset: int32, frameRepeat: int32, stencilPattern: Option[LCDPatternId] = none(LCDPatternId)): Animation =
  let firstFrame = bitmapTable.getBitmap(0)
  let frameCount: int32 = bitmapTable.getBitmapTableInfo().count.int32
  return Animation(
    bitmapTable: bitmapTable, 
    frameCount: frameCount,
    position: position,
    bounds: LCDRect(
      left: position.x, 
      right: position.x + firstFrame.width.int32, 
      top: position.y, 
      bottom: position.y + firstFrame.height.int32
    ),
    flip: flip,
    startOffset: startOffset,
    frameRepeat: frameRepeat,
    stencilPatternId: stencilPattern
  )

proc newAnimation*(bitmapTableId: BitmapTableId, position: Vertex, flip: LCDBitmapFlip, frameRepeat = 2'i32, randomStartOffset: bool, stencilPattern: Option[LCDPatternId] = none(LCDPatternId)): Animation =
  let annotatedTable = getOrLoadBitmapTable(bitmapTableId)
  return newAnimation(
    bitmapTable = annotatedTable.bitmapTable, 
    position = position,
    flip = flip,
    startOffset = if randomStartOffset: rand(annotatedTable.frameCount).int32 else: 0'i32,
    frameRepeat = frameRepeat,
    stencilPattern = stencilPattern
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

proc drawLine*(v0: Vertex, v1: Vertex, color: LCDColor = kColorBlack) {.inline.} =
  gfx.drawLine(v0.x, v0.y, v1.x, v1.y, 1, color)

proc fillCircle*(x, y: int32, radius: int32, color: LCDColor = kColorBlack ) {.inline.} =
  gfx.fillEllipse(x - radius,y - radius,radius * 2'i32, radius * 2'i32, 0f, 0f, color);

proc drawRoundRect*(x, y, width, height, radius, lineWidth: Natural, color: LCDSolidColor) {.inline.} =
  let r2 = radius * 2

  # lines
  gfx.fillRect(x + radius, y, width - r2, lineWidth, color)
  gfx.fillRect(x + width - lineWidth, y + radius, lineWidth, height - r2, color)
  gfx.fillRect(x + radius, y + height - lineWidth, width - r2, lineWidth, color)
  gfx.fillRect(x, y + radius, lineWidth, height - r2, color)

  # corners
  gfx.drawEllipse(x, y, r2, r2, lineWidth, -90'f, 0'f, color)
  gfx.drawEllipse(x + width - r2, y, r2, r2, lineWidth, 0'f, 90'f, color)
  gfx.drawEllipse(x + width - r2, y + height - r2, r2, r2, lineWidth, 90'f, 180'f, color)
  gfx.drawEllipse(x, y + height - r2, r2, r2, lineWidth, -180'f, -90'f, color)

proc fillRoundRect*(x, y, width, height, radius: Natural, color: LCDSolidColor) {.inline.} =
  let r2 = radius * 2

  gfx.fillRect(x + radius, y + radius, width - r2, height - r2, color) #center

  # body as a cross between the four corners
  # vertical body beam
  gfx.fillRect(x + radius, y, width - r2, height, color)
  # horizontal body beam
  gfx.fillRect(x, y + radius, width, height - r2, color)

  # corners
  gfx.fillEllipse(x, y, r2, r2, 270 ,0, color) # top left
  gfx.fillEllipse(x + width - r2, y, r2, r2, 0, 90, color) # top right
  gfx.fillEllipse(x + width - r2, y + height - r2, r2, r2, 90, 180, color) # bottom right
  gfx.fillEllipse(x, y + height - r2, r2, r2, 180, 270, color) # bottom left
  
# Rect

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

proc draw*(rect: Rect, color: LCDColor) {.inline.} =
  gfx.drawRect(rect.x, rect.y, rect.width, rect.height, color)

proc fill*(rect: Rect, color: LCDColor) {.inline.} =
  gfx.fillRect(rect.x, rect.y, rect.width, rect.height, color)

proc setScreenClipRect*(rect: Rect) {.inline.} =
  gfx.setClipRect(rect.x, rect.y, rect.width, rect.height)

proc drawRoundRect*(rect: Rect, radius: int32, lineWidth: int32, color: LCDSolidColor) {.inline.} =
  drawRoundRect(
    x= rect.x, 
    y= rect.y, 
    width= rect.width, 
    height= rect.height, 
    radius= radius, 
    lineWidth= lineWidth, 
    color= color
  )

proc fillRoundRect*(rect: Rect, radius: int32, color: LCDSolidColor) {.inline.} =
  fillRoundRect(
    x= rect.x, 
    y= rect.y, 
    width= rect.width, 
    height= rect.height, 
    radius= radius, 
    color= color
  )

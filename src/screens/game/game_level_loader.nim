{.push raises: [].}

import chipmunk7
import flatty
import chipmunk_utils
import options
import common/integrity
import common/utils
import sugar
import std/math
import std/json
import std/sequtils
import std/strutils
import std/tables
import std/random
import playdate/api
import game_types
import common/graphics_types
import common/graphics_utils
import common/data_utils
import level_meta/level_data
import level_meta/level_entity
import cache/bitmap_cache
import cache/bitmaptable_cache
import common/lcd_patterns

type
  ClassIds {.pure.} = enum
    Player = 1'u32, Coin = 2'u32, Killer = 3'u32, Finish = 4'u32, Star = 5'u32, SignPost = 6'u32,
    Flag = 7'u32, Gravity = 8'u32, TallBook = 9'u32, BowlingBall = 10'u32, Marble = 11'u32, TennisBall = 12'u32,
    TallPlank = 13'u32

const
  GID_HFLIP_MASK: uint32 = 1'u32 shl 31
  GID_VFLIP_MASK: uint32 = 1 shl 30
  GID_DIAG_FLIP_MASK: uint32 = 1 shl 29
  GID_UNUSED_FLIP_MASK: uint32 = 1 shl 28
  GID_FLIP_MASK: uint32 = GID_HFLIP_MASK or GID_VFLIP_MASK or GID_DIAG_FLIP_MASK or GID_UNUSED_FLIP_MASK
  GID_CLASS_MASK: uint32 = not GID_FLIP_MASK

  BITMAP_TABLE_SUFFIX: string = "-table-1" # suffix for bitmap table animations in the level editor

  D8_FALLBACK* = D8_UP

  ## offset of Chassis position (center Vect) from Player object top-left position
  vPlayerChassisOffset: Vect = v(40.0, 56.0)
  ## The amount of pixels the chassis center can be outside the level bounds before the game over
  chassisLevelBoundsSlop: Float = 50.Float

proc fallbackElasticity(objectType: Option[DynamicObjectType]): float32 =
  if objectType.isNone: return 0.0f
  case objectType.get:
    # keep in sync with editor defaults in game_objects.tsj
    of DynamicObjectType.BowlingBall: 0.05f
    of DynamicObjectType.Marble: 0.1f
    of DynamicObjectType.TennisBall: 0.6f
    else: 0.0f

proc toLCDPattern(str: string): LCDPattern =
  case str
    of "grid4": return patGrid4
    else: return nil

proc toDirection8(str: string): Direction8 =
  case str
    of "up": return D8_UP
    of "down": return D8_DOWN
    of "left": return D8_LEFT
    of "right": return D8_RIGHT
    of "up_left": return D8_UP_LEFT
    of "up_right": return D8_UP_RIGHT
    of "down_left": return D8_DOWN_LEFT
    of "down_right": return D8_DOWN_RIGHT
    else:
      print("Unknown direction: " & $str)
      return D8_FALLBACK

proc getProp[T](obj: LevelPropertiesHolder, name: string, mapper: JsonNode -> T, fallback: T): T {.raises: [], effectsOf: mapper.} =
  if obj.properties.isSome:
      let fillProp = obj.properties.get.findFirst(it => it.name == name)
      if fillProp.isSome:
        return mapper(fillProp.get.value)
  return fallback


proc fill(obj: LevelObjectEntity): LCDPattern =
  return obj.getProp(
    name = "fill",
    mapper = (node => node.getStr.toLCDPattern),
    fallback = nil
  )

proc count(obj: LevelObjectEntity): int32 =
  return obj.getProp(
    name = "count",
    mapper = (node => node.getInt.int32),
    fallback = 1'i32
  )

proc nutType(obj: LevelObjectEntity): int32 =
  return obj.getProp(
    name = "nutType",
    mapper = (node => node.getInt.int32 - 1'i32), # 0 is random, but we want 0 to be the first nut
    fallback = -1'i32
  )

proc direction8(obj: LevelObjectEntity): Direction8 =
  return obj.getProp(
    name = "direction",
    mapper = (node => node.getStr.toDirection8),
    fallback = D8_UP
  )

proc thickness(obj: LevelObjectEntity): float32 {.raises: [].} =
  return obj.getProp(
    name = "thickness",
    mapper = (node => node.getFloat.float32),
    fallback = 0.0f
  )

proc massMultiplier(obj: LevelObjectEntity): float32 =
  return obj.getProp(
    name = "massMultiplier",
    mapper = (node => node.getFloat.float32),
    fallback = 1.0f
  )

proc friction(obj: LevelObjectEntity): float32 =
  return obj.getProp(
    name = "friction",
    mapper = (node => node.getFloat.float32),
    fallback = 1.0f
  )

proc elasticity(obj: LevelObjectEntity, fallback: float32): float32 =
  return obj.getProp(
    name = "bounciness", # bounciness is used in the editor as a more understandable term
    mapper = (node => node.getFloat.float32),
    fallback = fallback
  )

proc startOffset(obj: LevelLayerEntity, frameCount: int32): int32 =
  result = obj.getProp(
    name = "startFrame",
    mapper = (node => node.getInt.int32),
    fallback = 0'i32
  )

  case result:
    of int32.low .. -1'i32: result = rand(frameCount).int32
    of 0 .. 1: result = 0
    else: discard # keep the value

proc frameRepeat(obj: LevelLayerEntity): int32 =
  return obj.getProp(
    name = "frameRepeat",
    mapper = (node => node.getInt.int32),
    fallback = 2'i32
  )


proc readDataFileContents(path: string): string {.raises: [Exception].} =
  try:
    let playdateFile = playdate.file
    let contentString = playdateFile.open(path, kFileReadAny).readString()
    return contentString
  except:
    print("Could not read " & $path)
    print(getCurrentExceptionMsg())
    raise getCurrentException()

proc parseJsonLevel(path: string): (LevelEntity, string) {.raises: [Exception].} =
  let jsonString = readDataFileContents(path)
  return parseJsonLevelContents(jsonString)

proc parseFlattyLevel(path: string): (LevelEntity, string) {.raises: [Exception].} =
  let flattyString = readDataFileContents(path)
  try:
    let levelEntity = flattyString.fromFlatty(LevelEntity)
    let contentHash = flattyString.levelContentHash()
    return (levelEntity, contentHash)
  except:
    print("parse Flatty Level failed:")
    print(getCurrentExceptionMsg())
    return (nil, "")

proc toVertex(obj: LevelVertexEntity): Vertex =
  return (obj.x, obj.y)

proc getPolyline(obj: LevelObjectEntity): Polyline {.raises: [].} =
  if obj.polyline.isSome:
    return newPolyline(vertices = obj.polyline.get.map(toVertex), thickness = obj.thickness)
  else:
    return emptyPolyline

proc `+`*(v1, v2: Vertex): Vertex = (v1[0] + v2[0], v1[1] + v2[1])

proc loadPolygon(level: var Level, obj: LevelObjectEntity): bool =
  if obj.polygon.isNone:
    return false

  var segments: seq[LevelVertexEntity] = obj.polygon.get
  # close the polygon by adding the first vertex to the end
  segments.add(segments[0])
  var vertices = segments.map(toVertex)

  let objOffset: Vertex = (obj.x, obj.y)

  if vertices.len < 3:
    print("SKIP Polygon has less than 3 vertices")
    return false # polygons require at least 3 vertices

  var bounds = LCDRect(left: int32.high, right: int32.low, top: int32.high, bottom: int32.low)

  # Offset the polygon by the object's position (localToWorld)
  for vertex in vertices.mItems():
    vertex = vertex + objOffset
    bounds.encapsulate(vertex)

  level.terrainPolygons.add(newPolygon(vertices = vertices, bounds = bounds, fill = obj.fill))
  return true

proc loadPolyline(level: var Level, obj: LevelObjectEntity): bool =
  let objOffset: Vertex = (obj.x, obj.y)
  var polyline: Polyline = obj.getPolyline()

  if polyline.vertices.len < 2:
    return false # polylines require at least 2 vertices

  # Offset the polyline by the object's position (localToWorld)
  for vertex in polyline.vertices.mItems():
    vertex = vertex + objOffset

  level.terrainPolylines.add(polyline)
  return true

proc lcdBitmapFlip(gid: uint32): LCDBitmapFlip =
  let hFlip: bool = (gid and GID_HFLIP_MASK).bool
  let vFlip: bool = (gid and GID_VFLIP_MASK).bool
  if hFlip and vFlip:
    return kBitmapFlippedXY
  elif vFlip:
    return kBitmapFlippedY
  elif hFlip:
    return kBitmapFlippedX
  else:
    return kBitmapUnflipped

proc tiledRectPosToCenterPos*(x,y,width,height: float32, rotDegrees: float32): Vect =
  let rotRad = rotDegrees.degToRad
  let cosRotation = cos(rotRad)
  let sinRotation = sin(rotRad)
  let centerX = width * 0.5f
  let centerY = height * 0.5f
  let rotatedCenterX = centerX * cosRotation - centerY * sinRotation
  let rotatedCenterY = centerX * sinRotation + centerY * cosRotation
  return v(x + rotatedCenterX, y.float32 + rotatedCenterY)

proc loadAsDynamicBox(level: Level, obj: LevelObjectEntity, objectType: Option[DynamicObjectType] = none(DynamicObjectType)): bool =
  if obj.width < 1 or obj.height < 1:
    return false

  let centerV = tiledRectPosToCenterPos(obj.x.float32, obj.y.float32, obj.width.float32, obj.height.float32, obj.rotation)
  let size = v(obj.width.float32, obj.height.float32)
  level.dynamicBoxes.add(newDynamicBoxSpec(
    position = centerV, 
    size = size,
    mass = obj.massMultiplier * size.area * 0.005f,
    angle = obj.rotation.degToRad,
    friction = obj.friction,
    elasticity = obj.elasticity(objectType.fallbackElasticity),
    objectType = objectType,
  ))
  return true


proc loadAsDynamicCircle(level: Level, obj: LevelObjectEntity, objectType: Option[DynamicObjectType] = none(DynamicObjectType)): bool =
  if obj.width < 1 or obj.height < 1:
    return false

  let centerV = v(obj.x.Float + obj.width/2, obj.y.Float + obj.height / 2)
  let radius = obj.width.float32 * 0.5f
  let area = PI * radius * radius 
  level.dynamicCircles.add(newDynamicCircleSpec(
    position = centerV, 
    radius = radius,
    mass = obj.massMultiplier * area * 0.005f,
    angle = obj.rotation.degToRad,
    friction = obj.friction,
    elasticity = obj.elasticity(objectType.fallbackElasticity),
    objectType = objectType,
  ))
  return true
    
proc loadGid(level: Level, obj: LevelObjectEntity): bool =
  if obj.gid.isNone:
    return false

  let gid = obj.gid.get
  let classId: ClassIds = (gid and GID_CLASS_MASK).ClassIds

  let position: Vertex = (obj.x, obj.y)

  case classId:
    of ClassIds.Player:
      # player = bike + rider. chassis center is 7 pixels below the player center
      level.initialChassisPosition = position.toVect + vPlayerChassisOffset
      if (gid and GID_HFLIP_MASK).bool:
        level.initialDriveDirection = DD_LEFT
      else:
        level.initialDriveDirection = DD_RIGHT
        
    of ClassIds.Coin:
      let nutType = obj.nutType
      let coinIndex: int32 = if nutType == -1: level.coins.len.int32 else: nutType

      level.coins.add(newCoin(position = position, count = obj.count, coinIndex = coinIndex))
    of ClassIds.Killer:
      level.killers.add(newKiller(position = position))
    of ClassIds.Finish:
      level.finish = newFinish(position, gid.lcdBitmapFlip)
    of ClassIds.Star:
      level.starPosition = some(position)
    of ClassIds.SignPost:
      let signpostBitmap = getOrLoadBitmap("images/signpost-dpad-down")
      level.assets.add(newTexture(
        image = signpostBitmap,
        position = position,
        flip = gid.lcdBitmapFlip
      ))
    of ClassIds.Flag:
      level.assets.add(newAnimation(
        bitmapTableId = BitmapTableId.Flag,
        position = position,
        flip = gid.lcdBitmapFlip,
        randomStartOffset = true
      ))
    of ClassIds.Gravity:
      let spec = newGravityZoneSpec(position, obj.direction8)
      level.gravityZones.add(spec)
    of ClassIds.TallBook:
      # todo: should a default mass be set?
      return loadAsDynamicBox(level, obj, some(DynamicObjectType.TallBook))
    of ClassIds.BowlingBall:
      return loadAsDynamicCircle(level, obj, some(DynamicObjectType.BowlingBall))
    of ClassIds.Marble:
      return loadAsDynamicCircle(level, obj, some(DynamicObjectType.Marble))
    of ClassIds.TennisBall:
      return loadAsDynamicCircle(level, obj, some(DynamicObjectType.TennisBall))
    of ClassIds.TallPlank:
      return loadAsDynamicBox(level, obj, some(DynamicObjectType.TallPlank))
  return true

proc loadRectangle(level: Level, obj: LevelObjectEntity): bool =
  if obj.polygon.isSome or obj.polyline.isSome or obj.ellipse.get(false) or obj.text.isSome:
    # it's a rectangle only if it is not something else
    return false

  if obj.width < 1 or obj.height < 1:
    return false

  if obj.`type` == "DynamicObject":
    return loadAsDynamicBox(level, obj)
  else:
    let objOffset: Vertex = (obj.x, obj.y)
    let width = obj.width
    let height = obj.height
    let vertices: seq[Vertex] = @[
      objOffset,
      objOffset + (0'i32, height),
      objOffset + (width, height),
      objOffset + (width, 0'i32),
      objOffset
    ]
    let bounds = LCDRect(left: obj.x, right: obj.x + width, top: obj.y, bottom: obj.y + height)
    level.terrainPolygons.add(newPolygon(vertices, bounds, obj.fill))
    return true

proc loadEllipse(level: var Level, obj: LevelObjectEntity): bool =
  if not obj.ellipse.get(false):
    return false

  if not (obj.`type` == "DynamicObject"):
    return false

  let centerV = tiledRectPosToCenterPos(obj.x.float32, obj.y.float32, obj.width.float32, obj.height.float32, obj.rotation)
  let radius = obj.width.float32 * 0.5f
  let area = PI * radius * radius 
  level.dynamicCircles.add(newDynamicCircleSpec(
    position = centerV,
    radius = radius,
    mass = obj.massMultiplier * area * 0.005f,
    angle = obj.rotation.degToRad,
    friction = obj.friction,
    objectType = none(DynamicObjectType),
  ))
  return true

proc loadText(level: var Level, obj: LevelObjectEntity): bool =
  if obj.text.isNone:
    return false

  let textObj = obj.text.get
  let halign = textObj.halign.get("left")
  let alignment = if(halign == "center"): kTextAlignmentCenter elif(halign == "right"): kTextAlignmentRight else: kTextAlignmentLeft

  var posX = obj.x
  var posY = obj.y
  if alignment == kTextAlignmentCenter:
    posX += obj.width div 2
  elif alignment == kTextAlignmentRight:
    posX += obj.width

  level.texts.add(newText(
    value = textObj.text,
    position = newVertex(posX, posY),
    alignment = alignment,
  ))
  return true

proc loadObjectLayer(level: var Level, layer: LevelLayerEntity) {.raises: [].} =
  if layer.objects.isNone: return

  for obj in layer.objects.get:
    if obj.`type` == "Reference":
      ## skip references / helpers
      continue

    discard level.loadPolygon(obj) or
    level.loadPolyline(obj) or
    level.loadGid(obj) or
    level.loadText(obj) or
    level.loadEllipse(obj) or
    # rect must be last because it is not specifically marked as such
    level.loadRectangle(obj)

proc loadImageLayer(level: var Level, layer: LevelLayerEntity) {.raises: [].} =
  if layer.image.isNone: return

  let position: Vertex = (layer.offsetx.get(0), layer.offsety.get(0))

  var imageName = layer.image.get
  imageName = imageName.rsplit('/', maxsplit=1)[^1] # remove path
  imageName = imageName.rsplit('.', maxsplit=1)[0] # remove extension
  if layer.`class` == some("HintsBackgroundLayer"):
    level.hintsPath = some(levelsBasePath & imageName)
  elif imageName.endswith(BITMAP_TABLE_SUFFIX):
    # bitmap table animation
    try:
      imageName.removeSuffix(BITMAP_TABLE_SUFFIX) # in-place
      let bitmapTable = gfx.newBitmapTable(levelsBasePath & imageName)
      let frameCount = bitmapTable.getBitmapTableInfo().count.int32

      level.assets.add(newAnimation(
        bitmapTable = bitmapTable,
        position = position,
        flip = kBitmapUnflipped,
        startOffset = layer.startOffset(frameCount),
        frameRepeat = layer.frameRepeat,
      ))
    except IOError:
      print("Could not load bitmap table: " & $imageName)
  else:
    # background image
    let imagePath = levelsBasePath & imageName
    let bitmap = getOrLoadBitmap(imagePath)
    level.background = some(bitmap)

proc loadLayer(level: var Level, layer: LevelLayerEntity) {.raises: [].} =
  if layer.visible == false:
    print "Skipping invisible layer " & $layer.name
    return

  case layer.`type`:
    of "objectgroup":
      level.loadObjectLayer(layer)
    of "imagelayer":
      level.loadImageLayer(layer)
    else:
      print("Unknown layer type: " & $layer.`type`)
      return

proc loadLevel*(path: string): Level {.raises: [Exception].} =
  print "Loading level: " & $path
  var level = Level(
    id: path,
    meta: getLevelMeta(path),
    terrainPolygons: @[],
    initialChassisPosition: v(80.0, 80.0),
    initialDriveDirection: DD_RIGHT,
  )
  
  markStartTime()
  let (levelEntity, contentHash) = if path.endsWith(jsonLevelFileExtensionWithDot): 
    parseJsonLevel(path)
  else: 
    parseFlattyLevel(path)
  printT("parsed levelEntity")
  
  level.contentHash = contentHash

  let size: Size = (levelEntity.width * levelEntity.tilewidth, levelEntity.height * levelEntity.tileheight)
  level.size = size
  # BB uses a y-axis that points up
  level.cameraBounds = newBB(
    l = 0.0,
    b = 0.0,
    r = (levelEntity.width * levelEntity.tilewidth).Float - displaySize.x,
    t = (levelEntity.height * levelEntity.tileheight).Float - displaySize.y
  )
  level.chassisBounds = newBB(
    l = -chassisLevelBoundsSlop,
    b = -chassisLevelBoundsSlop,
    r = levelEntity.width.Float * levelEntity.tilewidth.Float + chassisLevelBoundsSlop,
    t = levelEntity.height.Float * levelEntity.tileheight.Float + chassisLevelBoundsSlop
  )

  for layer in levelEntity.layers:
    level.loadLayer(layer)

  var vertexCounts: CountTable[Vertex] = CountTable[Vertex]()
  for polygon in level.terrainPolygons:
    for i in 0 ..< polygon.vertices.high: # skip the last vertex, which is the same as the first
      vertexCounts.inc(polygon.vertices[i])

  for polygon in level.terrainPolygons.mitems:
    var edgeSegments = newSeq[bool](polygon.vertices.len - 1) #todo not needed
    
    for idx in 0 ..< polygon.vertices.high:
      edgeSegments[idx] = vertexCounts[polygon.vertices[idx]] > 1 and vertexCounts[polygon.vertices[idx + 1]] > 1
    
    polygon.edgeIndices = edgeSegments
    assert polygon.edgeIndices.len == polygon.vertices.len - 1, "ERROR: edgeIndices length mismatch"

  return level

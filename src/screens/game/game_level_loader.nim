import chipmunk7
import options
import common/utils
import sugar
import std/json
import std/sequtils
import playdate/api
import game_types
import common/graphics_types
import common/graphics_utils
import common/data_utils
import cache/bitmap_cache
import cache/bitmaptable_cache
import common/lcd_patterns

type
  LevelPropertiesEntity = ref object of RootObj
    name: string
    value: JsonNode

  LevelVertexEntity {.bycopy.} = object
    x*: int32
    y*: int32
  LevelObjectEntity = ref object of RootObj
    id: int32 # unique object id
    gid: Option[uint32] # tile id including flip flags
    x, y: int32
    width*, height*: int32
    polygon: Option[seq[LevelVertexEntity]]
    properties: Option[seq[LevelPropertiesEntity]]
    polyline: Option[seq[LevelVertexEntity]]
    ellipse: Option[bool]
  
  LayerEntity = ref object of RootObj
    objects: Option[seq[LevelObjectEntity]]
  
  LevelEntity = ref object of RootObj
    width, height: int32
    tilewidth, tileheight: int32
    layers: seq[LayerEntity]

  ClassIds {.pure.} = enum
    Player = 1'u32, Coin = 2'u32, Killer = 3'u32, Finish = 4'u32, Star = 5'u32, SignPost = 6'u32,
    Flag = 7'u32, Gravity = 8'u32

const
  GID_HFLIP_MASK: uint32 = 1'u32 shl 31
  GID_VFLIP_MASK: uint32 = 1 shl 30
  GID_DIAG_FLIP_MASK: uint32 = 1 shl 29
  GID_UNUSED_FLIP_MASK: uint32 = 1 shl 28
  GID_FLIP_MASK: uint32 = GID_HFLIP_MASK or GID_VFLIP_MASK or GID_DIAG_FLIP_MASK or GID_UNUSED_FLIP_MASK
  GID_CLASS_MASK: uint32 = not GID_FLIP_MASK

  ## offset of Chassis position (center Vect) from Player object top-left position
  vPlayerChassisOffset: Vect = v(30.0, 36.0)
  ## The amount of pixels the chassis center can be outside the level bounds before the game over
  chassisLevelBoundsSlop: Float = 50.Float

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

proc toGravity(d8: Direction8): Vect =
  return case d8
    of D8_UP: v(0.0, -100.0f)
    of D8_DOWN: v(0.0, 100.0f)
    of D8_LEFT: v(-100.0f, 0.0)
    of D8_RIGHT: v(100.0f, 0.0)
    of D8_UP_LEFT: v(-70.71f, -70.71f)
    of D8_UP_RIGHT: v(70.71f, -70.71f)
    of D8_DOWN_LEFT: v(-70.71f, 70.71f)
    of D8_DOWN_RIGHT: v(70.71f, 70.71f)

proc getProp[T](obj: LevelObjectEntity, name: string, mapper: JsonNode -> T, fallback: T): T =
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

proc direction8(obj: LevelObjectEntity): Direction8 =
  return obj.getProp(
    name = "direction",
    mapper = (node => node.getStr.toDirection8),
    fallback = D8_UP
  )

proc requiredRotations(obj: LevelObjectEntity): int32 =
  return obj.getProp(
    name = "requiredRotations",
    mapper = (node => node.getInt.int32),
    fallback = 0'i32
  )

proc thickness(obj: LevelObjectEntity): float32 =
  return obj.getProp(
    name = "thickness",
    mapper = (node => node.getFloat.float32),
    fallback = 8.0f
  )


proc readDataFileContents(path: string): string {.raises: [].} =
  try:
    let playdateFile = playdate.file
    let jsonString = playdateFile.open(path, kFileReadAny).readString()
    return jsonString
  except:
    print("Could not read " & $path)
    print(getCurrentExceptionMsg())
    return ""

proc parseLevel(path: string): LevelEntity {.raises: [].} =
  let jsonString = readDataFileContents(path)
  try:
    return parseJson(jsonString).to(LevelEntity)
  except:
    print("Level parse failed:")
    print(getCurrentExceptionMsg())
    return nil

proc toVertex(obj: LevelVertexEntity): Vertex =
  return (obj.x, obj.y)

proc getPolygon(obj: LevelObjectEntity): Polygon {.raises: [].} =
  if obj.polygon.isSome:
    var segments: seq[LevelVertexEntity] = obj.polygon.get
    # close the polygon by adding the first vertex to the end
    segments.add(segments[0])
    return newPolygon(vertices = segments.map(toVertex), fill = obj.fill)
  else:
    return emptyPolygon

proc getPolyline(obj: LevelObjectEntity): Polyline {.raises: [].} =
  if obj.polyline.isSome:
    return newPolyline(vertices = obj.polyline.get.map(toVertex), thickness = obj.thickness)
  else:
    return emptyPolyline

proc `+`*(v1, v2: Vertex): Vertex = (v1[0] + v2[0], v1[1] + v2[1])

proc loadPolygon(level: var Level, obj: LevelObjectEntity): bool =
  let objOffset: Vertex = (obj.x, obj.y)
  var polygon: Polygon = obj.getPolygon()

  if polygon.vertices.len < 3:
    return false # polygons require at least 3 vertices

  # Offset the polygon by the object's position (localToWorld)
  for vertex in polygon.vertices.mItems():
    vertex = vertex + objOffset

  level.terrainPolygons.add(polygon)

proc loadPolyline(level: var Level, obj: LevelObjectEntity): bool =
  let objOffset: Vertex = (obj.x, obj.y)
  var polyline: Polyline = obj.getPolyline()

  if polyline.vertices.len < 2:
    return false # polylines require at least 2 vertices

  # Offset the polyline by the object's position (localToWorld)
  for vertex in polyline.vertices.mItems():
    vertex = vertex + objOffset

  level.terrainPolylines.add(polyline)

proc loadGid(level: Level, obj: LevelObjectEntity): bool =
  if obj.gid.isNone:
    return false

  let gid = obj.gid.get
  let hFlip: bool = (gid and GID_HFLIP_MASK).bool
  let classId: ClassIds = (gid and GID_CLASS_MASK).ClassIds

  let position: Vertex = (obj.x, obj.y)

  case classId:
    of ClassIds.Player:
      # player = bike + rider. chassis center is 7 pixels below the player center
      level.initialChassisPosition = position.toVect + vPlayerChassisOffset
      if hFlip:
        level.initialDriveDirection = DD_LEFT
      else:
        level.initialDriveDirection = DD_RIGHT
        
    of ClassIds.Coin:
      level.coins.add(newCoin(position = position, count = obj.count))
    of ClassIds.Killer:
      level.killers.add(position)
    of ClassIds.Finish:
      level.finishPosition = position
      level.finishRequiredRotations = obj.requiredRotations
    of ClassIds.Star:
      level.starPosition = some(position)
    of ClassIds.SignPost:
      level.assets.add(Texture(
        image: getOrLoadBitmap("images/signpost_dpad_down"),
        position: position,
        flip: if hFlip: kBitmapFlippedX else: kBitmapUnflipped
      ))
    of ClassIds.Flag:
      level.assets.add(newAnimation(
        bitmapTableId = BitmapTableId.Flag,
        position = position,
        flip = if hFlip: kBitmapFlippedX else: kBitmapUnflipped,
        randomStartOffset = true
      ))
    of ClassIds.Gravity:
      level.assets.add(newAnimation(
        bitmapTableId = BitmapTableId.Gravity,
        position = position,
        flip = if hFlip: kBitmapFlippedX else: kBitmapUnflipped,
        randomStartOffset = true
      ))
      let gravityZone = newGravityZone(
        position = position,
        gravity = obj.direction8().toGravity(),
      )
      level.gravityZones.add(gravityZone)
  return true

proc loadRectangle(level: Level, obj: LevelObjectEntity): bool =
  if obj.polygon.isSome or obj.polyline.isSome or obj.ellipse.get(false):
    # it's a rectangle only if it is not a polygon, polyline or ellipse
    return false

  if obj.width < 1 or obj.height < 1:
    return false

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
  level.terrainPolygons.add(newPolygon(vertices, obj.fill()))
  return true

proc loadLayer(level: var Level, layer: LayerEntity) {.raises: [].} =
  if layer.objects.isNone: return

  for obj in layer.objects.get:
    discard level.loadPolygon(obj) or
    level.loadPolyline(obj) or
    level.loadGid(obj) or
    level.loadRectangle(obj)

proc loadLevel*(path: string): Level =
  var level = Level(
    id: path,
    terrainPolygons: @[],
    initialChassisPosition: v(80.0, 80.0),
    initialDriveDirection: DD_RIGHT,
  )
  
  let levelEntity = parseLevel(path)
  let size: Size = (levelEntity.width * levelEntity.tilewidth, levelEntity.height * levelEntity.tileheight)
  level.size = size
  # BB uses a y-axis that points up
  level.cameraBounds = newBB(
    l = 0.0,
    b = 0.0,
    r = (levelEntity.width * levelEntity.tilewidth).Float - displaySize.x,
    t = (levelEntity.height * levelEntity.tileheight).Float - displaySize.y
  )
  print("cameraBounds: " & $level.cameraBounds)
  level.chassisBounds = newBB(
    l = -chassisLevelBoundsSlop,
    b = -chassisLevelBoundsSlop,
    r = levelEntity.width.Float * levelEntity.tilewidth.Float + chassisLevelBoundsSlop,
    t = levelEntity.height.Float * levelEntity.tileheight.Float + chassisLevelBoundsSlop
  )

  for layer in levelEntity.layers:
    level.loadLayer(layer)
    
  return level

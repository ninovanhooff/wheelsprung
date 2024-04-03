import chipmunk7
import options
import utils
import std/json
import std/sequtils
import playdate/api
import game_types
import graphics_types
import graphics_utils
import cache/bitmap_cache
import cache/bitmaptable_cache

type 
  LevelVertexEntity {.bycopy.} = object
    x*: int32
    y*: int32
  LevelObjectEntity = ref object of RootObj
    id: int32 # unique object id
    gid: Option[uint32] # tile id including flip flags
    x, y: int32
    width*, height*: int32
    polygon: Option[seq[LevelVertexEntity]]
    polyline: Option[seq[LevelVertexEntity]]
    ellipse: Option[bool]
  
  LayerEntity = ref object of RootObj
    objects: Option[seq[LevelObjectEntity]]
  
  LevelEntity = ref object of RootObj
    width, height: int32
    tilewidth, tileheight: int32
    layers: seq[LayerEntity]

  ClassIds {.pure.} = enum
    Player = 1'u32, Coin = 2'u32, Killer = 3'u32, Finish = 4'u32, Star = 5'u32, SignPost = 6'u32, Flag = 7'u32

const
  GID_HFLIP_MASK: uint32 = 1'u32 shl 31
  GID_VFLIP_MASK: uint32 = 1 shl 30
  GID_DIAG_FLIP_MASK: uint32 = 1 shl 29
  GID_UNUSED_FLIP_MASK: uint32 = 1 shl 28
  GID_FLIP_MASK: uint32 = GID_HFLIP_MASK or GID_VFLIP_MASK or GID_DIAG_FLIP_MASK or GID_UNUSED_FLIP_MASK
  GID_CLASS_MASK: uint32 = not GID_FLIP_MASK

  ## offset of Chassis position (center Vect) from Player object top-left position
  vPlayerChassisOffset: Vect = v(30.0, 39.0)
  ## The amount of pixels the chassis center can be outside the level bounds before the game over
  chassisLevelBoundsSlop: Float = 50.Float

let kFileReadAny: FileOptions = cast[FileOptions]({kFileRead, kFileReadData})


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
  return [obj.x, obj.y]

proc getPolygon(obj: LevelObjectEntity): Polygon {.raises: [].} =
  if obj.polyline.isSome:
    return obj.polyline.get.map(toVertex)
  elif obj.polygon.isSome:
    var segments: seq[LevelVertexEntity] = obj.polygon.get
    # close the polygon by adding the first vertex to the end
    segments.add(segments[0])
    return segments.map(toVertex)
  else:
    return @[]

proc `+`*(v1, v2: Vertex): Vertex = [v1[0] + v2[0], v1[1] + v2[1]]

proc loadPolygon(level: Level, obj: LevelObjectEntity): bool =
  let objOffset: Vertex = [obj.x, obj.y]
  var polygon: Polygon = obj.getPolygon()
  if polygon.len < 2:
    return false

  let lastIndex = polygon.high

  # Offset the polygon by the object's position (localToWorld)
  for i in 0..lastIndex:
    polygon[i] = polygon[i] + objOffset

  level.terrainPolygons.add(polygon)

proc loadGid(level: Level, obj: LevelObjectEntity): bool =
  if obj.gid.isNone:
    return false

  let gid = obj.gid.get
  let hFlip: bool = (gid and GID_HFLIP_MASK).bool
  let classId: ClassIds = (gid and GID_CLASS_MASK).ClassIds

  let position: Vertex = [obj.x, obj.y]

  case classId:
    of ClassIds.Player:
      # player = bike + rider. chassis center is 7 pixels below the player center
      level.initialChassisPosition = position.toVect + vPlayerChassisOffset
      if hFlip:
        level.initialDriveDirection = DD_LEFT
      else:
        level.initialDriveDirection = DD_RIGHT
        
    of ClassIds.Coin:
      level.coins.add(position)
    of ClassIds.Killer:
      level.killers.add(position)
    of ClassIds.Finish:
      level.finishPosition = position
    of ClassIds.Star:
      level.starPosition = some(position)
    of ClassIds.SignPost:
      level.assets.add(Texture(
        image: getOrLoadBitmap("images/signpost_dpad_down"),
        position: position,
        flip: if hFlip: kBitmapFlippedX else: kBitmapUnflipped
      ))
    of ClassIds.Flag:
      let annotatedTable = getOrLoadBitmapTable(BitmapTableId.Flag)
      let animation = Animation(
        bitmapTable: annotatedTable.bitmapTable, 
        frameCount: annotatedTable.frameCount,
        position: position,
        flip: if hFlip: kBitmapFlippedX else: kBitmapUnflipped,
        startOffset: 0'i32,
      )
      # let animation: Animation = newAnimation(
      #   bitmapTableId: BitmapTableId.Flag,
      #   position: position,
      #   flip: if hFlip: kBitmapFlippedX else: kBitmapUnflipped,
      #   randomStartOffset: true
      # )
      level.assets.add(animation)
  return true

proc loadRectangle(level: Level, obj: LevelObjectEntity): bool =
  if obj.polygon.isSome or obj.polyline.isSome or obj.ellipse.get(false):
    # it's a rectangle only if it is not a polygon, polyline or ellipse
    return false

  if obj.width < 1 or obj.height < 1:
    return false

  let objOffset: Vertex = [obj.x, obj.y]
  let width = obj.width
  let height = obj.height
  let rect: seq[Vertex] = @[
    objOffset,
    objOffset + [width, 0'i32],
    objOffset + [width, height],
    objOffset + [0'i32, height],
    objOffset
  ]
  level.terrainPolygons.add(rect)
  return true

proc loadLayer(level: Level, layer: LayerEntity) {.raises: [].} =
  if layer.objects.isNone: return

  for obj in layer.objects.get:
    discard level.loadPolygon(obj) or level.loadGid(obj) or level.loadRectangle(obj)

proc loadLevel*(path: string): Level =
  let level = Level(
    terrainPolygons: @[],
    initialChassisPosition: v(80.0, 80.0),
    initialDriveDirection: DD_RIGHT,
  )
  
  let levelEntity = parseLevel(path)

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

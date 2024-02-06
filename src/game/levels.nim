import chipmunk7
import options
import utils
import std/json
import std/sequtils
import playdate/api
import game_types

type 
  LevelVertexEntity {.bycopy.} = object
    x*: int32
    y*: int32
  LevelObjectEntity = ref object of RootObj
    x, y: int32
    width*, height*: int32
    gid: Option[uint32]
    polygon: Option[seq[LevelVertexEntity]]
    polyline: Option[seq[LevelVertexEntity]]
  
  LayerEntity = ref object of RootObj
    objects: Option[seq[LevelObjectEntity]]
  
  LevelEntity = ref object of RootObj
    layers: seq[LayerEntity]

  ClassIds {.pure.} = enum
    Player = 1, Coin = 2

const 
  GID_HFLIP_MASK: uint32 = 1 shl 31
  GID_VFLIP_MASK: uint32 = 1 shl 30
  GID_DIAG_FLIP_MASK: uint32 = 1 shl 29
  GID_FLIP_MASK: uint32 = GID_HFLIP_MASK or GID_VFLIP_MASK or GID_DIAG_FLIP_MASK
  GID_CLASS_MASK: uint32 = not GID_FLIP_MASK

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

proc loadPolygon(level: Level, obj: LevelObjectEntity) =
  let objOffset: Vertex = [obj.x, obj.y]
  var polygon: Polygon = obj.getPolygon()
  if polygon.len < 2:
    return

  let lastIndex = polygon.high

  # Offset the polygon by the object's position (localToWorld)
  for i in 0..lastIndex:
    polygon[i] = polygon[i] + objOffset
    print("segment: " & $polygon[i])

  level.groundPolygons.add(polygon)

proc loadGid(level: Level, obj: LevelObjectEntity) =
  if obj.gid.isSome:
    let gid = obj.gid.get
    let hFlip: bool = (gid and GID_HFLIP_MASK).bool
    let blah = GID_CLASS_MASK
    let classId: ClassIds = (gid and GID_CLASS_MASK).ClassIds

    # TODO check if tyhe uint32 are correct, casting probably not needed
    let vCenter = v(
      obj.x.Float + obj.width.Float*0.5, 
      obj.y.Float - obj.height.Float*0.5 # Tiled uses bottom-left as origin
    )

    case classId:
      of ClassIds.Player:
        # player = bike + rider. chassis center is 7 pixels below the player center
        level.initialChassisPosition = vCenter + v(0.0, 7.0)
        if hFlip:
          level.initialDriveDirection = DD_LEFT
        else:
          level.initialDriveDirection = DD_RIGHT
          
      of ClassIds.Coin:
        level.coins.add(vCenter)

proc loadLayer(level: Level, layer: LayerEntity) {.raises: [].} =
  if layer.objects.isNone: return

  for obj in layer.objects.get:
    level.loadPolygon(obj)
    level.loadGid(obj)

proc loadLevel*(path: string): Level =
  let level = Level(
    groundPolygons: @[],
    initialChassisPosition: v(80.0, 80.0),
    initialDriveDirection: DD_RIGHT,
  )
  
  let levelEntity = parseLevel(path)

  for layer in levelEntity.layers:
    level.loadLayer(layer)
    
  return level

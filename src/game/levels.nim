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
        polygon: Option[seq[LevelVertexEntity]]
        polyline: Option[seq[LevelVertexEntity]]
    
    LayerEntity = ref object of RootObj
        objects: Option[seq[LevelObjectEntity]]
    
    LevelEntity = ref object of RootObj
        layers: seq[LayerEntity]

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

proc loadLayer(level: Level, layer: LayerEntity) {.raises: [].} =
    if layer.objects.isNone: return

    for obj in layer.objects.get:
        let objOffset: Vertex = [obj.x, obj.y]
        var polygon: Polygon = obj.getPolygon()
        if polygon.len < 2:
            continue

        let lastIndex = polygon.high

        # Offset the polygon by the object's position (localToWorld)
        for i in 0..lastIndex:
            polygon[i] = polygon[i] + objOffset
            print("segment: " & $polygon[i])

        level.groundPolygons.add(polygon)

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

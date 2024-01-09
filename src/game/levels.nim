import chipmunk7
import options
import utils
import std/json
import playdate/api

const groundFriction = 10.0f

type 
    LevelObject = ref object of RootObj
        x, y: float
        polygon: Option[seq[Vect]]
        polyline: Option[seq[Vect]]
    
    Layer = ref object of RootObj
        objects: Option[seq[LevelObject]]
    
    Level = ref object of RootObj
        layers: seq[Layer]

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

proc parseLevel(path: string): Level {.raises: [].} =
    let jsonString = readDataFileContents(path)
    try:
        return parseJson(jsonString).to(Level)
    except:
        print("Level parse failed:")
        print(getCurrentExceptionMsg())
        return nil

proc getSegments(obj: LevelObject): seq[Vect] {.raises: [].} =
    if obj.polyline.isSome:
        return obj.polyline.get
    elif obj.polygon.isSome:
        var segments: seq[Vect] = obj.polygon.get
        segments.add(segments[0])
        return segments
    else:
        return @[]

proc loadLayer(layer: Layer, space: Space) {.raises: [].} =
    if layer.objects.isNone:
        return

    for obj in layer.objects.get:
        let objOffset = v(obj.x, obj.y)
        var segments: seq[Vect] = obj.getSegments()
        if segments.len < 2:
            continue

        let lastIndex = segments.high

        for i in 0..lastIndex:
            segments[i] = segments[i] + objOffset

        for i in 1..lastIndex:
            var groundSegment = newSegmentShape(space.staticBody, segments[i-1], segments[i], 0f)
            groundSegment.friction = groundFriction
            discard space.addShape(groundSegment)

proc loadLevel*(path: string): Space {.raises: [].} =
    let space = newSpace()
    let level = parseLevel(path)

    for layer in level.layers:
        loadLayer(layer, space)
      
    return space

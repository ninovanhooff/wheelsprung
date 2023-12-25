import chipmunk7
import options
import std/json
import playdate/api

const groundFriction = 10.0f

type 
    LevelObject = ref object of RootObj
        name: string
        x, y: float
        width, height: float
        rotation: float
        polygon: seq[Vect]
    
    Layer = ref object of RootObj
        name: string
        objects: Option[seq[LevelObject]]
    
    Level = ref object of RootObj
        layers: seq[Layer]

proc readDataFileContents(path: string): string {.raises: [].} =
    try:
        let playdateFile = playdate.file
        let jsonString = playdateFile.open(path, kFileReadData).readString()
        return jsonString
    except:
        playdate.system.logToConsole("Could not read " & $path)
        playdate.system.logToConsole(getCurrentExceptionMsg())
        return ""

proc parseLevel(path: string): Level {.raises: [].} =
    let jsonString = readDataFileContents(path)
    try:
        return parseJson(jsonString).to(Level)
    except:
        playdate.system.logToConsole("Level parse failed:")
        playdate.system.logToConsole(getCurrentExceptionMsg())
        return nil

proc loadLayer(layer: Layer, space: Space) {.raises: [].} =
    if layer.objects.isNone:
        return

    for obj in layer.objects.get:
        let objOffset = v(obj.x, obj.y)
        var poly: seq[Vect] = obj.polygon

        let lastIndex = poly.high

        for i in 0..lastIndex:
            poly[i] = poly[i] + objOffset

        for i in 0..lastIndex:
            playdate.system.logToConsole("Adding segment from " & $i & " to " & $((i + 1) mod (lastIndex-1)))
            var groundSegment = newSegmentShape(space.staticBody, poly[i], poly[(i + 1) mod (lastIndex+1)], 0f)
            groundSegment.friction = groundFriction
            discard space.addShape(groundSegment)

proc loadLevel*(path: string): Space {.raises: [].} =
    let space = newSpace()
    let level = parseLevel(path)

    for layer in level.layers:
        loadLayer(layer, space)
      
    return space

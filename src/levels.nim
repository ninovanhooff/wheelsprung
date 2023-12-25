import chipmunk7
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
        objects: seq[LevelObject]
    
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
    for obj in layer.objects:
        let objOffset = v(obj.x, obj.y)
        var poly: seq[Vect] = obj.polygon

        for i in 0..poly.high:
            poly[i] = poly[i] + objOffset

        for i in 1..poly.high:
            var groundSegment = newSegmentShape(space.staticBody, poly[i-1], poly[i], 0f)
            groundSegment.friction = groundFriction
            discard space.addShape(groundSegment)

proc loadLevel*(path: string): Space {.raises: [].} =
    let space = newSpace()
    let level = parseLevel(path)

    for layer in level.layers:
        loadLayer(layer, space)
      
    return space

{.push raises: [].}

# Do NOT import any playdate api directly or indirectly
# Because this file is imported by update_level_meta.nim which is used
# As a standalone script
import options
import common/integrity
import std/json
import std/strutils

type
  LevelPropertiesEntity* = ref object of RootObj
    name*: string
    value*: JsonNode
  LevelTextEntity* = ref object of RootObj
    halign*: Option[string]
    text*: string
  LevelVertexEntity* {.bycopy.} = object
    x*: int32
    y*: int32
  LevelPropertiesHolder* = ref object of RootObj
    properties*: Option[seq[LevelPropertiesEntity]]
  LevelObjectEntity* = ref object of LevelPropertiesHolder
    id*: int32 # unique object id
    gid*: Option[uint32] # tile id including flip flags
    x*, y*: int32
    width*, height*: int32
    rotation*: float32
    polygon*: Option[seq[LevelVertexEntity]]
    polyline*: Option[seq[LevelVertexEntity]]
    text*: Option[LevelTextEntity]
    ellipse*: Option[bool]
    `type`*: string
  LevelLayerEntity* = ref object of LevelPropertiesHolder
    objects*: Option[seq[LevelObjectEntity]]
    name*: Option[string]
    visible*: bool
    image*: Option[string]
    offsetx*, offsety*: Option[int32]
    `type`*: string
    `class`*: Option[string]

  LevelEntity* = ref object of RootObj
    width*, height*: int32
    tilewidth*, tileheight*: int32
    layers*: seq[LevelLayerEntity]

proc parseJsonLevelContents*(jsonString: string): (LevelEntity, string) {.raises: [].} =
  try:
    let levelEntity = jsonString.parseJson().to(LevelEntity)
    let contentHash = jsonString.levelContentHash()
    return (levelEntity, contentHash)
  except:
    echo("Level parse failed:")
    echo(getCurrentExceptionMsg())
    return (nil, "")

proc toFlatty*(levelEntity: LevelEntity): string =
  let flatString = levelEntity.toFlatty()
  return flatString
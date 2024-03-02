import playdate/api
import std/json
import options
import utils

type Config* = ref object of RootObj
  lastOpenedLevel*: Option[string]

var config: Config

proc saveConfig(config: Config) =
  print "Saving config", repr(config)
  let jsonString: seq[byte] = cast[seq[byte]]($(%config))
  try:
    let file = playdate.file.open("config.json", kFileWrite)
    let lenWritten = file.write(jsonString, jsonString.len.uint32)
    if lenWritten != jsonString.len:
      print "Failed to write config file, wrote", lenWritten, "bytes out of", jsonString.len, "bytes"
    file.close()
  except:
    print "Failed to save config file", getCurrentExceptionMsg()

proc createAndSaveConfig(): Config =
  let config = Config(lastOpenedLevel: none(string))
  saveConfig(config)
  return config

proc loadConfig(): Config =
  try:
    let jsonString = playdate.file.open("config.json", kFileReadData).readString()
    let config = jsonString.parseJson().to(Config)
    print "Loaded config", repr(config)
    return config
  except:
    print "Failed to load config file:", getCurrentExceptionMsg()
    return createAndSaveConfig()

proc getConfig*(): Config =
  if config == nil:
    config = loadConfig()
  return config

proc setLastOpenedLevel*(levelPath: string) =
  discard getConfig()
  config.lastOpenedLevel = some(levelPath)
  saveConfig(config)

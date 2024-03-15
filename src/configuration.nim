import playdate/api
import std/json
import sugar
import options
import utils
import configuration_types

var config: Config

proc save*(config: Config) =
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

proc createAndsave(): Config =
  let config = Config(lastOpenedLevel: none(string))
  save(config)
  return config

proc makeDir(dir: string) =
  print "Creating directory", dir
  try:
    playdate.file.mkdir(dir)
  except:
    print "Failed to create directory", dir, getCurrentExceptionMsg()

proc loadConfig(): Config =
  try:
    let jsonString = playdate.file.open("config.json", kFileReadData).readString()
    let config = jsonString.parseJson().to(Config)
    print "Loaded config", repr(config)
    return config
  except:
    print "Failed to load config file:", getCurrentExceptionMsg()
    # we usually end up here when the data folder doesn't exist yet.
    # this is a good time to create the levels folder too.
    makeDir("levels")
    return createAndsave()

proc getConfig*(): Config =
  if config == nil:
    config = loadConfig()
  return config

proc updateConfig*(update: Config -> void) =
  discard getConfig() # Ensure config is loaded
  update(config)
  save(config)

proc setLastOpenedLevel*(levelPath: string) =
  updateConfig(proc (config: Config) = 
    config.lastOpenedLevel = some(levelPath)
  )

proc getDPadInputType*(self: Config): DPadInputType =
  return config.dPadInputType.get(DPadInputType.Jolt)

proc incDpadInputType*(config: Config) =
  config.dPadInputType = some(
    config.getDPadInputType().nextWrapped()
  )

proc decDpadInputType*(config: Config) =
  config.dPadInputType = some(
    config.getDPadInputType().prevWrapped()
  )

import playdate/api
import std/json
import sugar
import options
import common/utils
import common/shared_types
import configuration/configuration_types
import common/json_utils

var config: Config

proc save*(config: Config) =
  print "Saving", repr(config)
  saveJson(config, "config.json")

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
  let optConfig = loadJson[Config]("config.json")
  if optConfig.isSome:
    print "Loaded", repr(optConfig.get)
    return optConfig.get
  else:
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
  return config.dPadInputType.get(DPadInputType.Constant)

proc incDpadInputType*(config: Config) =
  config.dPadInputType = some(
    config.getDPadInputType().nextWrapped()
  )

proc decDpadInputType*(config: Config) =
  config.dPadInputType = some(
    config.getDPadInputType().prevWrapped()
  )

proc getDPadInputMultiplier*(self: Config): float =
  return config.dPadInputMultiplier.get(0.9)

proc incDpadInputMultiplier*(config: Config) =
  config.dPadInputMultiplier = some(
    min(config.getDPadInputMultiplier() + 0.1, 2.0)
  )

proc decDpadInputMultiplier*(config: Config) =
  config.dPadInputMultiplier = some(
    max(config.getDPadInputMultiplier() - 0.1, 0.1)
  )

proc getTiltAttitudeAdjustEnabled*(self: Config): bool =
  return config.tiltAttitudeAdjustEnabled.get(false)

proc toggleTiltAttitudeAdjustEnabled*(config: Config) =
  config.tiltAttitudeAdjustEnabled = some(
    not config.getTiltAttitudeAdjustEnabled()
  )

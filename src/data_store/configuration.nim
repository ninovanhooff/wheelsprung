import playdate/api
import sugar
import options
import common/utils
import common/shared_types
import data_store/configuration_types
import common/data_utils

var config: Config

proc save*(config: Config) =
  print "Saving", repr(config)
  saveJson(config, "config.json")

proc createAndSave(): Config =
  let config = Config()
  save(config)
  return config

proc loadConfig(): Config =
  let optConfig = loadJson[Config]("config.json")
  if optConfig.isSome:
    print "Loaded", repr(optConfig.get)
    return optConfig.get
  else:
    # we usually end up here when the data folder doesn't exist yet.
    # this is a good time to create the levels folder too.
    makeDir("levels")
    return createAndSave()

proc getConfig*(): Config =
  if config == nil:
    config = loadConfig()
  return config

proc updateConfig*(update: Config -> void) =
  discard getConfig() # Ensure config is loaded
  update(config)
  save(config)

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

proc getClassicCameraEnabled*(self: Config): bool =
  return config.classicCameraEnabled.get(false)

proc toggleClassicCameraEnabled*(config: Config) =
  config.classicCameraEnabled = some(
    not config.classicCameraEnabled.get(false)
  )

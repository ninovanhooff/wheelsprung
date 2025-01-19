import playdate/api
import common/utils

template system*: untyped = playdate.system

const
  forwardInfluence = 0.3f
  backwardInfluence = 1.0f - forwardInfluence

type AccelerometerInput* {.requiresInit.} = ref object of RootObj
  smoothAccelX: float32
  accelXLimit: float32

proc newAccelerometerInput*(accelXLimit: float32): AccelerometerInput =
  print("Accelerometer Input Created")
  system.setPeripheralsEnabled(kAccelerometer)
  AccelerometerInput(smoothAccelX: 0.0, accelXLimit: accelXLimit)


proc destroyAccelerometerInput*(accelerometerInput: AccelerometerInput) =
  print "Accelerometer Input Destroyed"
  system.setPeripheralsEnabled(kNone)

proc getX*(state: AccelerometerInput): float32 =
  let accelX: float32 = system.getAccelerometer[0]
  state.smoothAccelX = (accelX * forwardInfluence) + (state.smoothAccelX*backwardInfluence)
  return clamp(state.smoothAccelX / state.accelXLimit, -1.0f, 1.0f)

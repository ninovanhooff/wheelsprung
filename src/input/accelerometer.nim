import playdate/api
import utils

template system*: untyped = playdate.system

const
  forwardInfluence = 0.3f
  averagingFactor = 1.0f + forwardInfluence

type 
  AccelereometerAxisState* {.requiresInit.} = ref object of RootObj
    smoothAccel: float32
    accelLimit: float32
    calibration: float32
  AccelerometerInput* {.requiresInit.} = ref object of RootObj
    axes: tuple[
      x: AccelereometerAxisState,
      y: AccelereometerAxisState
    ]

proc newAccelerometerInput*(accelXLimit: float32): AccelerometerInput =
  print("Accelerometer Input Created")
  system.setPeripheralsEnabled(kAccelerometer)
  AccelerometerInput(
    axes: (
      x: AccelereometerAxisState(smoothAccel: 0.0f, accelLimit: accelXLimit, calibration: 0f),
      y: AccelereometerAxisState(smoothAccel: 0.0f, accelLimit: accelXLimit, calibration: 0f) # Y todo use own limit
    )
  )

proc updateAxis*(state: AccelereometerAxisState, accel: float32) =
  state.smoothAccel = (accel * forwardInfluence +  state.smoothAccel) / averagingFactor

proc update*(state: AccelerometerInput) =
  let accel = system.getAccelerometer
  updateAxis(state.axes.x, accel.x)
  updateAxis(state.axes.y, accel.y)
  # updateAxis(state.axes.y, accel.y)

proc calibrate*(state: AccelerometerInput): float32 =
    for axis in state.axes.fields:
      axis.calibration = axis.smoothAccel

proc destroyAccelerometerInput*(accelerometerInput: AccelerometerInput) =
  print "Accelerometer Input Destroyed"
  system.setPeripheralsEnabled(kNone)

proc getAxisValue(axis: AccelereometerAxisState): float32 {.inline.} =
  return clamp(axis.smoothAccel - axis.calibration, -1.0f, 1.0f)

proc getX*(state: AccelerometerInput): float32 =
  return getAxisValue(state.axes.x)

proc getY*(state: AccelerometerInput): float32 =
  return getAxisValue(state.axes.y)

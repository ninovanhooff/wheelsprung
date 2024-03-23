import accelerometer
import sugar

var accelerometerInput: AccelerometerInput

proc withAccelerometerInput*(callback: AccelerometerInput -> auto): auto =
  if(accelerometerInput.isNil):
    accelerometerInput = newAccelerometerInput(0.5f)
  return callback(accelerometerInput)

proc updateInputs*(): void =
  if not accelerometerInput.isNil:
    accelerometerInput.update()

proc calibrateAccelerometer*(): void =
  discard withAccelerometerInput( (accel) => accel.calibrate() )

proc getAccelerometerX*(): float32 =
  withAccelerometerInput( (accel) => accel.getX() )

proc getAccelerometerY*(): float32 =
  withAccelerometerInput( (accel) => accel.getY() )
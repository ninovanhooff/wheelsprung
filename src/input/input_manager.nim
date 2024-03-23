import accelerometer

var accelerometerInput: AccelerometerInput


proc getAccelerometerX*(): float32 =
  if(accelerometerInput.isNil):
    accelerometerInput = newAccelerometerInput(0.5f)
  accelerometerInput.getX()
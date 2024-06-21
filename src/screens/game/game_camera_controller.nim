import chipmunk7
import game_types
import common/utils

const
  speedStep = 2

proc newCameraController*(maxHistoryLength: int, integralThreshold: Float): CameraController =
  return CameraController(
    maxHistoryLength: maxHistoryLength, 
    integralThreshold: integralThreshold,
    lastTarget: 0f, # todo param
    speed : 0,
    history : @[],
    errorIntegral : 0
  )
  
proc sign(x: Float): Float =
  if x < 0:
    return -1
  elif x > 0:
    return 1
  else:
    return 0

proc update*(self: CameraController, value: Float, target: Float): Float =
  let error = target - value
  result = value
  self.history.add(error)
  self.errorIntegral += error
  if self.history.len > self.maxHistoryLength:
    self.errorIntegral -= self.history[0]
    self.history.delete(0)

  ## todo with floats, this condition will never be true (equality is not guaranteed with floats)
  if self.speed == 0 and abs(self.lastTarget - target) < 1f: # todo contained a lastTarget nil-check
    if abs(error) > speedStep:
      self.lastTarget = target
      result += sign(error) * speedStep
  elif abs(self.errorIntegral) > self.integralThreshold:
    self.speed += sign(self.errorIntegral) * speedStep
    self.errorIntegral = 0
    result += self.speed
  else:
    result += self.speed

  self.lastTarget = target

  # print "result: ", result.int32, " speed: ", self.speed.int32, " error: ", error.int32, " integral: ", self.errorIntegral.int32, "integralThreshold: ", self.integralThreshold.int32
  return result
import math

type
  PIDController* = object
    kp, ki, kd: float
    setpoint: float
    integral: float
    previousError: float

proc newPIDController*(kp, ki, kd, setpoint: float): PIDController =
  PIDController(kp: kp, ki: ki, kd: kd, setpoint: setpoint, integral: 0.0, previousError: 0.0)

proc setTargetPosition*(controller: var PIDController, targetPosition: float) =
  controller.setpoint = targetPosition

proc updatePID*(controller: var PIDController, currentPosition: float): float =
  let error = controller.setpoint - currentPosition
  controller.integral += error
  let derivative = error - controller.previousError
  controller.previousError = error
  result = controller.kp * error + controller.ki * controller.integral + controller.kd * derivative

proc resetPID*(controller: var PIDController, setPoint: float) =
  controller.integral = 0.0
  controller.previousError = 0.0
  controller.setpoint = setPoint

proc moveCamera*(currentPosition: float, controlSignal: float): float =
  let moveStep = 2.0 * round(controlSignal / 2.0)
  result = currentPosition + moveStep

proc stepToTarget*(controller: var PIDController, currentPosition: float, target: float): float =
  controller.setTargetPosition(target)
  let controlSignal = controller.updatePID(currentPosition)
  return moveCamera(currentPosition, controlSignal)

# # Unit tests
# suite "PID Camera Controller Tests":
#   test "PID Controller moves camera towards target position":
#     var cameraPosition = 0.0
#     let targetPosition = 100.0

#     var pid = initPIDController(0.5, 0.01, 0.1, targetPosition)

#     for i in 0..20:
#       let previousPosition = cameraPosition
#       let controlSignal = updatePID(pid, cameraPosition)
#       cameraPosition = moveCamera(cameraPosition, controlSignal)
#       let positionDifference = cameraPosition - previousPosition
#       echo "Time: ", i , "s, Camera Position: ", cameraPosition, ", Position Difference: ", positionDifference

#     # Check if the camera position is close to the target position
#     check(abs(cameraPosition - targetPosition) < 4.0)

#   test "PID Controller moves camera in multiples of two pixels":
#     var cameraPosition = 0.0
#     let targetPosition = 50.0

#     var pid = initPIDController(0.5, 0.01, 0.1, targetPosition)

#     for i in 0..20:
#       let previousPosition = cameraPosition
#       let controlSignal = updatePID(pid, cameraPosition)
#       cameraPosition = moveCamera(cameraPosition, controlSignal)
#       let positionDifference = cameraPosition - previousPosition
#       echo "Time: ", i, "s, Camera Position: ", cameraPosition, ", Position Difference: ", positionDifference

#     # Check if the camera position is a multiple of two pixels
#     check(cameraPosition mod 2 == 0)
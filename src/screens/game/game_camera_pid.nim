import game_types
import chipmunk7, chipmunk_utils
import common/graphics_utils
import pid_controller
import common/utils

const
  cameraLerpSpeed = 0.05
  cameraDirectionOffsetX = 50.0
  cameraVelocityOffsetFactorX = 0.25
  cameraVelocityOffsetFactorY = 0.25

var camXController = initPIDController(
  kp = 0.5,
  ki = 0.01,
  kd = 0.1,
  setpoint = 0.0
)
var camYController = initPIDController(
  kp = 0.5,
  ki = 0.01,
  kd = 0.1,
  setpoint = 0.0
)

var 
  chassisVelocity: Vect
  targetCameraOffset: Vect

proc resetCameraControllers*(target: Vect) =
  # todo seems not to be called on every level. Move controllers into GameState
  print "Resetting camera: ", target
  camXController.resetPID(target.x)
  camYController.resetPID(target.y)

proc updateCamera*(state: GameState, snapToTarget: bool = false) =
  chassisVelocity = state.chassis.velocity
  targetCameraOffset = v(
    state.driveDirection * cameraDirectionOffsetX + chassisVelocity.x * cameraVelocityOffsetFactorX,
    chassisVelocity.y * cameraVelocityOffsetFactorY
  )

  if snapToTarget:
    state.cameraOffset = targetCameraOffset
    let cameraTarget = state.chassis.position - halfDisplaySize + state.cameraOffset
    state.camera = cameraTarget
    resetCameraControllers(cameraTarget)
  else:
    state.cameraOffset = state.cameraOffset.vlerp(targetCameraOffset, cameraLerpSpeed)
    let cameraTarget = state.level.cameraBounds.clampVect(
      state.chassis.position - halfDisplaySize + state.cameraOffset
    )
    # todo combine 3 calls into 1
    camXController.setTargetPosition(cameraTarget.x)
    camYController.setTargetPosition(cameraTarget.y)
    let controlX = camXController.updatePID(state.camera.x)
    let controlY = camYController.updatePID(state.camera.y)
    let newX = moveCamera(state.camera.x, controlX)
    let newY = moveCamera(state.camera.y, controlY)
    print "xStep: ", $(newX - state.camera.x), "yStep: ", $(newY - state.camera.y)
    state.camera = state.level.cameraBounds.clampVect(
      v(newX, newY)
    ).round()
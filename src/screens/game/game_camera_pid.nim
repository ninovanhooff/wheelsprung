import game_types
import chipmunk7, chipmunk/chipmunk_utils
import common/graphics_utils
import pid_controller

const
  cameraLerpSpeed = 0.05
  cameraDirectionOffsetX = 50.0
  cameraVelocityOffsetFactorX = 0.25
  cameraVelocityOffsetFactorY = 0.25



var 
  chassisVelocity: Vect
  targetCameraOffset: Vect

proc newGameCamPID(target: float32 = 0f): PIDController =
  newPIDController(
    kp = 0.5,
    ki = 0.01,
    kd = 0.1,
    setpoint = target
  )

proc resetCameraControllers(state: GameState, target: Vect) =
  # print "Resetting camera: ", target

  state.camXController = newGameCamPID(target.x)
  state.camYController = newGameCamPID(target.y)

proc updateCameraPid*(state: GameState, snapToTarget: bool = false) =
  chassisVelocity = state.chassis.velocity
  targetCameraOffset = v(
    state.driveDirection * cameraDirectionOffsetX + chassisVelocity.x * cameraVelocityOffsetFactorX,
    chassisVelocity.y * cameraVelocityOffsetFactorY
  )

  if snapToTarget:
    state.cameraOffset = targetCameraOffset
    let cameraTarget = state.chassis.position - halfDisplaySize + state.cameraOffset
    state.camera = cameraTarget
    state.resetCameraControllers(cameraTarget)
  else:
    state.cameraOffset = state.cameraOffset.vlerp(targetCameraOffset, cameraLerpSpeed)
    let cameraTarget = state.level.cameraBounds.clampVect(
      state.chassis.position - halfDisplaySize + state.cameraOffset
    )
    let newX = state.camXController.stepToTarget(state.camera.x, cameraTarget.x)
    let newY = state.camYController.stepToTarget(state.camera.y, cameraTarget.y)
    state.camera = state.level.cameraBounds.clampVect(
      v(newX, newY)
    ).round()
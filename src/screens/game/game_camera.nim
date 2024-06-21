import game_types
import game_camera_controller
import chipmunk7, chipmunk_utils
import common/graphics_utils
import common/utils

const
  cameraLerpSpeed = 0.05
  cameraDirectionOffsetX = 50.0
  cameraVelocityOffsetFactorX = 0.15
  cameraVelocityOffsetFactorY = 0.15 # TODO

  maxHistLength = 12
  integralThresholdX = maxHistLength * 25
  integralThresholdY = maxHistLength * 17

var 
  chassisVelocity: Vect
  targetCameraOffset: Vect

proc updateCamera*(state: GameState, snapToTarget: bool = false) =
  var camera = state.camera

  ## calculate target
  let targetCameraOffset = v(
    state.driveDirection * cameraDirectionOffsetX + chassisVelocity.x * cameraVelocityOffsetFactorX,
    chassisVelocity.y * cameraVelocityOffsetFactorY
  )
  let target = state.chassis.position - halfDisplaySize + targetCameraOffset

  ## update camera
  if snapToTarget:
    state.camControllerX = newCameraController(
      maxHistoryLength = maxHistLength,
      integralThreshold = integralThresholdX,
    )
    state.camControllerY = newCameraController(
      maxHistoryLength = maxHistLength,
      integralThreshold = integralThresholdY,
    )
    camera = target
  else:
    camera = v(
      state.camControllerX.update(
        value = camera.x,
        target = target.x
      ),
      # target.y
      state.camControllerY.update(
        value = camera.y,
        target = target.y
      )
    )

  ## clamp camera
  state.camera = state.level.cameraBounds.clampVect(
    camera
  ).round()

  print "camera: ", state.camera, " target: ", target, " offset: ", targetCameraOffset

# proc roundToNearestInt*(v: Vect, increment: int32): Vect =
#   v(
#     roundToNearestInt(v.x, increment).Float,
#     roundToNearestInt(v.y, increment).Float
#   )

proc updateLerpCamera*(state: GameState, snapToTarget: bool = false) =
  chassisVelocity = state.chassis.velocity
  targetCameraOffset = v(
    state.driveDirection * cameraDirectionOffsetX + chassisVelocity.x * cameraVelocityOffsetFactorX,
    chassisVelocity.y * cameraVelocityOffsetFactorY
  )
  if snapToTarget:
    state.cameraOffset = targetCameraOffset
  elif state.cameraOffset.vdistsq(targetCameraOffset) > 4.0: # NOTE: this is a squared distance (faster)
    state.cameraOffset = state.cameraOffset.vlerp(targetCameraOffset, cameraLerpSpeed)
  
  state.camera = state.level.cameraBounds.clampVect(
    state.chassis.position - halfDisplaySize + state.cameraOffset
  ).round()
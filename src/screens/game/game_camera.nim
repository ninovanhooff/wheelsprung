import game_types
import chipmunk7, chipmunk_utils
import common/graphics_utils

const
  cameraLerpSpeed = 0.05
  cameraDirectionOffsetX = 50.0
  cameraVelocityOffsetFactorX = 0.25
  cameraVelocityOffsetFactorY = 0.25

var 
  chassisVelocity: Vect
  targetCameraOffset: Vect
proc updateCamera*(state: GameState, snapToTarget: bool = false) =
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
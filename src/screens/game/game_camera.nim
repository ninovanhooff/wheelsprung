import game_types
import utils
import chipmunk7, chipmunk_utils
import graphics_utils

const
  cameraLerpSpeed = 0.05
  cameraDirectionOffsetX = 50.0
  cameraVelocityOffsetFactorX = 0.25

var 
  targetCameraOffset: Vect
proc updateCamera*(state: GameState) =
  # instead of `let targetCameraOffset = v( ...` use the var
  targetCameraOffset = v(
    state.driveDirection * cameraDirectionOffsetX + state.chassis.velocity.x * cameraVelocityOffsetFactorX,
    0.0
  )
  print "targetCameraOffset: ", targetCameraOffset, state.chassis.velocity.x, state.driveDirection
  if state.cameraOffset.vdistsq(targetCameraOffset) > 4.0: # NOTE: this is a squared distance (faster)
    state.cameraOffset = state.cameraOffset.vlerp(targetCameraOffset, cameraLerpSpeed)
  
  state.camera = state.level.cameraBounds.clampVect(
    state.chassis.position - halfDisplaySize + state.cameraOffset
  ).round()
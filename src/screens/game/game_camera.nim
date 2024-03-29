import game_types
import math
import chipmunk7, chipmunk_utils
import graphics_utils

proc updateCamera*(state: GameState) =
  state.camera = state.level.cameraBounds.clampVect(
    state.chassis.position - halfDisplaySize
  ).round()
import chipmunk7
import math
import common/shared_types

const
  # by keeping tickRate and timeStep constant, the game slows down if the frame rate drops
  # this is better than letting the physics engine run at a variable rate
  # which can cause instability.
  # Also, this might be desirable for slow motion effects.
  physicsTickRate* = 50
  timeStep*: int32 = 1000.Milliseconds div physicsTickRate
  timeStepSeconds*: Seconds = (timeStep.float64 / 1000.0)
  riderOffset* = v(-4.0, -18.0) # offset from chassis center
  HALF_PI*: float = PI * 0.5

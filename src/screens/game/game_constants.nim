import chipmunk7
import math
import common/shared_types

const
  # by keeping tickRate and timeStep constant, the game slows down if the frame rate drops
  # this is better than letting the physics engine run at a variable rate
  # which can cause instability.
  # Also, this might be desirable for slow motion effects.
  physicsTickRate* = 50 
    ## typically equal to the frame rate, but frame rate may vary depending on slow motion or user settings
  timeStep*: int32 = 1000.Milliseconds div physicsTickRate
  timeStepSeconds64*: float64 = timeStep.float64 / 1_000.0'f64
    ## timeStepSeconds64 is used to advance the physics simulation, let's go for maximum precision to minimise drift
  riderOffset* = v(-4.0, -18.0) # offset from chassis center
  HALF_PI*: float = PI * 0.5

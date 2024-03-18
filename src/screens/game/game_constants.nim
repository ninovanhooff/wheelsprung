import chipmunk7
import math

const
  # by keeping tickRate and timeStep constant, the game slows down if the frame rate drops
  # this is better than letting the physics engine run at a variable rate
  # which can cause instability.
  # Also, this might be desirable for slow motion effects.
  physicsTickRate* = 50.0
  timeStep* = 1.0 / physicsTickRate
  riderOffset* = v(-4.0, -18.0) # offset from chassis center
  HALF_PI*: float = PI * 0.5

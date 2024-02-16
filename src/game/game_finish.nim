import std/[sugar, sequtils]
import chipmunk7
import chipmunk_utils, graphics_utils
import game_types

const
  vFinishOffset = v(19.0, 19.0) # half of the finish image size

proc addfinish*(space: Space, finish: Finish): Body =
  let body = space.addBox(
    pos = toVect(finish) + vFinishOffset,
    radius = finishRadius,
    mass = 1.0,
    shapeFilter = GameShapeFilters.Finish,
    collisionType = GameCollisionTypes.Finish,
  )
  body.bodyType = BODY_TYPE
  body

import std/[random, math, sugar, sequtils]
import chipmunk7
import chipmunk_utils, graphics_utils
import game_types

const
  killerRadius = 10.0
  vKillerOffset = v(killerRadius, killerRadius)

proc addKiller(space: Space, killer: Killer): Body =
  let body = space.addCircle(
    pos = toVect(killer) + vKillerOffset,
    radius = killerRadius,
    mass = 1.0,
    shapeFilter = GameShapeFilters.Killer,
    collisionType = GameCollisionTypes.Killer,
  )
  body.bodyType = BODY_TYPE_KINEMATIC
  body.angularVelocity=3.0
  body.angle=rand(2.0*PI)
  body

proc addKillers*(space: Space, level: Level): seq[Body] =
  level.killers.map(killer => space.addKiller(killer))
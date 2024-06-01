import std/[random, math, sugar, sequtils]
import chipmunk7
import chipmunk_utils
import common/graphics_utils
import game_types

const
  killerRadius: Float = 10f
  killerFriction: Float = 10f
  vKillerOffset = v(killerRadius, killerRadius)

proc addKiller(space: Space, killer: Killer): Body =
  let body = space.addCircle(
    pos = toVect(killer) + vKillerOffset,
    radius = killerRadius,
    mass = 1.0,
    shapeFilter = GameShapeFilters.Killer,
    collisionType = GameCollisionTypes.Killer,
    friction = killerFriction,
  )[0]
  body.bodyType = BODY_TYPE_STATIC
  body.angularVelocity=3.0
  body.angle=rand(2.0*PI)
  body

proc addKillers*(space: Space, level: Level): seq[Body] =
  level.killers.map(killer => space.addKiller(killer))

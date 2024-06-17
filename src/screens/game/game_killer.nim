import std/[random, math, sugar, sequtils]
import playdate/api
import chipmunk7
import chipmunk_utils
import common/graphics_utils
import cache/bitmaptable_cache
import game_types

const
  killerFriction: Float = 10f
  vKillerOffset = v(killerRadius, killerRadius)

var killerImageTable: AnnotatedBitmapTable

proc addKiller(space: Space, killer: Killer): Killer =
  let body = space.addCircle(
    pos = v(killer.bounds.left.Float, killer.bounds.top.Float) + vKillerOffset,
    radius = killerRadius,
    mass = 1.0,
    shapeFilter = GameShapeFilters.Killer,
    collisionType = GameCollisionTypes.Killer,
    friction = killerFriction,
  )[0]
  body.bodyType = BODY_TYPE_KINEMATIC
  body.angularVelocity=3.0
  body.angle=rand(2.0*PI)
  return newKiller(killer.bounds, body)

proc initGameKiller*() =
  killerImageTable = getOrLoadBitmapTable(BitmapTableId.Killer)


proc addKillers*(space: Space, level: Level): seq[Killer] =
  level.killers.map(killer => space.addKiller(killer))

proc drawKillers*(killers: seq[Killer], camera: Camera) =
    let viewport = LCD_SCREEN_RECT.offsetBy(camera.toVertex())

    for killer in killers:
      if not viewport.intersects(killer.bounds):
        continue
      let body = killer.body
      let killerScreenPos = body.position - camera
      killerImageTable.drawRotated(killerScreenPos, body.angle)

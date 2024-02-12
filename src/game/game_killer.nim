import std/[random, math]
import chipmunk7
import chipmunk_utils
import game_types

proc initGameKillers*(state: GameState) =
  let body = state.space.addCircle(
    pos = v(80.0,100.0),
    radius = 8.0,
    mass = 1.0,
    shapeFilter = GameShapeFilters.Killer,
    collisionType = GameCollisionTypes.Killer,
  )

  body.bodyType = BODY_TYPE_KINEMATIC
  body.angularVelocity=3.0
  body.angle=rand(2.0*PI)
  state.killers.add(body)

import chipmunk7
import common/graphics_utils
import game_types
import std/options

const
  starRadius = 10.0
  vStarOffset = v(starRadius, starRadius)

proc initGameStar*(state: GameState) =
  # asssigment by copy
  if state.starEnabled:
    state.remainingStar = state.level.starPosition
  else:
    state.remainingStar = none(Star)

proc addStar*(space: Space, star: Star) =
  let shape: Shape = newCircleShape(space.staticBody, starRadius, toVect(star) + vStarOffset)
  shape.sensor = true # only detect collisions, don't apply forces to colliders
  shape.collisionType = GameCollisionTypes.Star
  shape.filter = GameShapeFilters.Collectible
  discard space.addShape(shape)

import chipmunk7
import common/graphics_utils
import game_types

const
  starRadius = 10.0
  vStarOffset = v(starRadius, starRadius)

proc initGameStar*(state: GameState) =
  # asssigment by copy
  state.remainingStar = state.level.starPosition

proc addStar*(space: Space, star: Star) =
  let shape: Shape = newCircleShape(space.staticBody, starRadius, toVect(star) + vStarOffset)
  shape.sensor = true # only detect collisions, don't apply forces to colliders
  shape.collisionType = GameCollisionTypes.Star
  shape.filter = GameShapeFilters.Collectible
  discard space.addShape(shape)

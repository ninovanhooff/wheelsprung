import chipmunk7
import common/graphics_utils
import game_types
import sound/game_sound
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

let starPostStepCallback: PostStepFunc = proc(space: Space, starShape: pointer, unused: pointer) {.cdecl.} =
  # print("star post step callback")
  let state = cast[GameState](space.userData)
  let shape = cast[Shape](starShape)
  space.removeShape(shape)
  state.remainingStar = none[Star]()
  if state.gameResult.isSome:
    # star can be collected after the game ended
    state.gameResult.get.starCollected = true
  playStarSound()

let starBeginFunc*: CollisionBeginFunc = proc(arb: Arbiter; space: Space; unused: pointer): bool {.cdecl.} =
  var
    shapeA: Shape
    shapeB: Shape
  arb.shapes(addr(shapeA), addr(shapeB))
  discard space.addPostStepCallback(starPostStepCallback, shapeA, nil)
  return false # don't process the collision further


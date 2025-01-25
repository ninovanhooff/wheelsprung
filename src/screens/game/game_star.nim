import chipmunk7
import playdate/api
import common/graphics_utils
import game_types
import sound/game_sound
import std/options
import cache/bitmap_cache
import cache/bitmaptable_cache

const
  starRadius = 10.0
  vStarOffset = v(starRadius, starRadius)

proc addStar*(state: GameState) =
  let star: Vertex = if state.starEnabled:
    # assignment by copy
    state.remainingStar = state.level.starPosition
    state.remainingStar.get
  else:
    state.remainingStar = none(Star)
    return
  
  let space = state.space
  let shape: Shape = newCircleShape(space.staticBody, starRadius, toVect(star) + vStarOffset)
  shape.sensor = true # only detect collisions, don't apply forces to colliders
  shape.collisionType = GameCollisionTypes.Star
  shape.filter = GameShapeFilters.Collectible
  discard space.addShape(shape)

proc drawStar*(remainingStar: Star, camState: CameraState) =
  let starScreenPos = remainingStar - camState.camVertex
  # animate highlight at 1/4 speed
  let highlightImage = getOrLoadBitmapTable(BitmapTableId.PickupHighlight).getBitmap(camState.frameCounter div 4)
  highlightImage.draw(starScreenPos[0] - 5, starScreenPos[1] - 5, kBitmapUnflipped)
  # draw the star
  getOrLoadBitmap(BitmapId.Acorn).draw(starScreenPos[0], starScreenPos[1], kBitmapUnflipped)

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


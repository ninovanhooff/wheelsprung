import std/options
import playdate/api
import chipmunk7
import common/utils
import common/graphics_utils
import cache/bitmaptable_cache
import game_types

const 
  gravityZoneRadius = 20.0.Float
  vGravityZoneCenterOffset = v(gravityZoneRadius, gravityZoneRadius)
  DIAGONAL_GRAVVITY_MAGNITUDE: float32 = 0.70710678118 * GRAVITY_MAGNITUDE


proc toVect(d8: Direction8): Vect =
  return case d8
    of D8_UP: v(0.0, -GRAVITY_MAGNITUDE)
    of D8_DOWN: v(0.0, GRAVITY_MAGNITUDE)
    of D8_LEFT: v(-GRAVITY_MAGNITUDE, 0.0)
    of D8_RIGHT: v(GRAVITY_MAGNITUDE, 0.0)
    of D8_UP_LEFT: v(-DIAGONAL_GRAVVITY_MAGNITUDE, -DIAGONAL_GRAVVITY_MAGNITUDE)
    of D8_UP_RIGHT: v(DIAGONAL_GRAVVITY_MAGNITUDE, -DIAGONAL_GRAVVITY_MAGNITUDE)
    of D8_DOWN_LEFT: v(-DIAGONAL_GRAVVITY_MAGNITUDE, DIAGONAL_GRAVVITY_MAGNITUDE)
    of D8_DOWN_RIGHT: v(DIAGONAL_GRAVVITY_MAGNITUDE, DIAGONAL_GRAVVITY_MAGNITUDE)

proc toGravityAnimation(spec: GravityZoneSpec): Animation =
  let d8 = spec.direction
  let position = spec.position
  var flip = kBitmapUnflipped
  var bitmmapTableId: BitmapTableId
  case d8
    of D8_UP: 
      bitmmapTableId = BitmapTableId.GravityUp
      flip = kBitmapUnflipped
    of D8_DOWN:
      bitmmapTableId = BitmapTableId.GravityUp
      flip = kBitmapFlippedY
    of D8_LEFT:
      bitmmapTableId = BitmapTableId.GravityRight
      flip = kBitmapFlippedX
    of D8_RIGHT:
      bitmmapTableId = BitmapTableId.GravityRight
      flip = kBitmapUnflipped
    of D8_UP_LEFT:
      bitmmapTableId = BitmapTableId.GravityUpRight
      flip = kBitmapFlippedX
    of D8_UP_RIGHT:
      bitmmapTableId = BitmapTableId.GravityUpRight
      flip = kBitmapUnflipped
    of D8_DOWN_LEFT:
      bitmmapTableId = BitmapTableId.GravityUpRight
      flip = kBitmapFlippedXY
    of D8_DOWN_RIGHT:
      bitmmapTableId = BitmapTableId.GravityUpRight
      flip = kBitmapFlippedY

  return newAnimation(
    bitmapTableId = bitmmapTableId,
    position = position,
    flip = flip,
    frameRepeat = 3,
    randomStartOffset = true,
    stencilPattern = some(Gray)
  )

proc addGravityZones(space: Space, gravityZones: seq[GravityZone]) =
  for gravityZone in gravityZones:
    let vCenter = gravityZone.position.toVect + vGravityZoneCenterOffset
    let shape = space.addShape(space.staticBody.newCircleShape(gravityZoneRadius, vCenter))
    shape.sensor = true # only detect collisions, don't apply forces to colliders
    shape.collisionType = GameCollisionTypes.GravityZone
    shape.filter = GameShapeFilters.GravityZone
    shape.userData = cast[DataPointer](gravityZone)

proc addGravityZones*(state: GameState) =
  # assignment by copy
  print "initGravityZones"
  state.gravityZones = @[]
  for spec in state.level.gravityZones:
    let animation = spec.toGravityAnimation()
    let gravityZone = newGravityZone(
      position = spec.position,
      direction = spec.direction,
      animation = animation
    )
    state.gravityZones.add(gravityZone)
  print "state.gravityZones: " & repr(state.gravityZones)
  state.space.addGravityZones(state.gravityZones)

proc drawGravityZones*(gravityZones: seq[GravityZone], activeDirection: Direction8, camState: CameraState) =
  for gravityZone in gravityZones:
    let stencilPatternId = if gravityZone.direction == activeDirection: none(LCDPatternId) else: some(Gray)
    gravityZone.animation.stencilPatternId = stencilPatternId
    gravityZone.animation.drawAsset(camState)

let gravityZonePostStepCallback: PostStepFunc = proc(space: Space, gravityShape: pointer, unused: pointer) {.cdecl raises: [].} =
  let gravityShape = cast[Shape](gravityShape)
  let gravityZone = cast[GravityZone](gravityShape.userData)
  echo "hit gravity zone:" & repr(gravityZone)

  let state = cast[GameState](space.userData)
  state.gravityDirection = gravityZone.direction
  let newGravity = gravityZone.direction.toVect
  space.gravity = newGravity

let gravityZoneBeginFunc*: CollisionBeginFunc = proc(arb: Arbiter; space: Space; unused: pointer): bool {.cdecl.} =
  print "gravityZoneBeginFunc"
  var shapeA, shapeB: Shape
  arb.shapes(addr(shapeA), addr(shapeB))
  discard space.addPostStepCallback(gravityZonePostStepCallback, shapeA, nil)
  return false

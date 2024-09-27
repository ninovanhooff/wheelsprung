import chipmunk7
import common/graphics_utils
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

proc addGravityZones*(space: Space, gravityZones: seq[GravityZone]) =
  for gravityZone in gravityZones:
    let vCenter = gravityZone.position.toVect + vGravityZoneCenterOffset
    let shape = space.addShape(space.staticBody.newCircleShape(gravityZoneRadius, vCenter))
    shape.sensor = true # only detect collisions, don't apply forces to colliders
    shape.collisionType = GameCollisionTypes.GravityZone
    shape.filter = GameShapeFilters.GravityZone
    shape.userData = cast[DataPointer](gravityZone)

let gravityZonePostStepCallback: PostStepFunc = proc(space: Space, gravityShape: pointer, unused: pointer) {.cdecl raises: [].} =
  let gravityShape = cast[Shape](gravityShape)
  let gravityZone = cast[GravityZone](gravityShape.userData)
  echo "hit gravity zone:" & repr(gravityZone)
  let newGravity = gravityZone.direction.toVect
  space.gravity = newGravity

let gravityZoneBeginFunc*: CollisionBeginFunc = proc(arb: Arbiter; space: Space; unused: pointer): bool {.cdecl.} =
  var shapeA, shapeB: Shape
  arb.shapes(addr(shapeA), addr(shapeB))
  discard space.addPostStepCallback(gravityZonePostStepCallback, shapeA, nil)
  return false

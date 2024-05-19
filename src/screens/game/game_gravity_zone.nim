import chipmunk7
import common/graphics_utils
import game_types
import common/utils

const 
  gravityZoneRadius = 20.0.Float
  vGravityZoneCenterOffset = v(gravityZoneRadius, gravityZoneRadius)

proc addGravityZones*(space: Space, gravityZones: seq[GravityZone]) =
  for index, gravityZone in gravityZones:
    let vCenter = gravityZone.position.toVect + vGravityZoneCenterOffset
    let shape = space.addShape(space.staticBody.newCircleShape(gravityZoneRadius, vCenter))
    shape.sensor = true # only detect collisions, don't apply forces to colliders
    shape.collisionType = GameCollisionTypes.GravityZone
    shape.filter = GameShapeFilters.GravityZone
    shape.userData = cast[DataPointer](gravityZone)


let gravityZoneBeginFunc*: CollisionBeginFunc = proc(arb: Arbiter; space: Space; unused: pointer): bool {.cdecl.} =
  var 
    shapeA: Shape
    shapeB: Shape
  arb.shapes(addr(shapeA), addr(shapeB))
  space.gravity=cast[GravityZone](shapeA.userData).gravity
  print "new gravity", space.gravity
  return false # don't process the collision further

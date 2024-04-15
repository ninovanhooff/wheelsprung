import chipmunk7
import graphics_utils
import game_types
import utils

const 
  vGravityZoneRadius = 20.0.Float

proc addGravityZones*(space: Space, gravityZones: seq[GravityZone]) =
  for index, gravityZone in gravityZones:
    let pos = gravityZone.position.toVect
    let shape = space.addShape(space.staticBody.newCircleShape(vGravityZoneRadius, pos))
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
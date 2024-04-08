import chipmunk7
import graphics_utils
import game_types

const 
  vGravityZoneRadius = 20.0.Float

proc addGravityZones*(space: Space, gravityZones: seq[GravityZone]) =
  for index, gravityZone in gravityZones:
    let pos = gravityZone.position.toVect
    let shape = space.addShape(space.staticBody.newCircleShape(vGravityZoneRadius, pos))
    shape.sensor = true # only detect collisions, don't apply forces to colliders
    shape.collisionType = GameCollisionTypes.GravityZone
    shape.filter = GameShapeFilters.GravityZone
    shape.userData = cast[DataPointer](index)

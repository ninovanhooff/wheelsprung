import chipmunk7
import chipmunk_utils
import game_types

const
  objectsFriction = 10.0

proc addPhysicsObjects*(space: Space, boxes: seq[PhysicsBox]) =
  # Add the polygons as segment shapes to the physics space
  for obj in boxes:
      discard space.addBox(
        obj.position, obj.size, 
        mass = obj.mass,
        friction = objectsFriction,
        collisionType=GameCollisionTypes.DynamicObject,
        shapeFilter = GameShapeFilters.DynamicObject
      )

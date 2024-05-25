import playdate/api
import chipmunk7
import chipmunk_utils
import common/utils
import common/graphics_utils
import game_types

const
  objectsFriction = 10.0

proc adddynamicObjects*(state: GameState) =
  # Add the polygons as segment shapes to the physics space
  for obj in state.level.physicsBoxes:
    state.dynamicObjectShapes.add(
      state.space.addBox(
        obj.position, obj.size, 
        mass = obj.mass,
        friction = objectsFriction,
        collisionType=GameCollisionTypes.DynamicObject,
        shapeFilter = GameShapeFilters.DynamicObject
      )[1]
    )

proc drawDynamicObjects*(state: GameState) =
  let camera = state.camera
  for shape in state.dynamicObjectShapes:
    if shape.kind == cpPolyShape:
      let poly = cast[PolyShape](shape)
      let numVerts = poly.count
      for i in 0 ..< numVerts:
        let a = localToWorld(poly.body, poly.vert(i)) - camera
        let b = localToWorld(poly.body, poly.vert((i+1) mod numVerts)) - camera
        gfx.drawLine(a.x.toInt, a.y.toInt, b.x.toInt, b.y.toInt, 1, kColorBlack);
    else:
      print "drawDynamicObjects: Unknown shape kind: ", shape.kind

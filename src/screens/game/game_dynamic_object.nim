import playdate/api
import std/math
import chipmunk7
import chipmunk_utils
import common/utils
import common/graphics_utils
import game_types

proc adddynamicObjects*(state: GameState) =
  # Add the polygons as segment shapes to the physics space
  for obj in state.level.dynamicBoxes:
    state.dynamicObjectShapes.add(
      state.space.addBox(
        obj.position, obj.size, 
        mass = obj.mass,
        angle = obj.angle,
        friction = obj.friction,
        collisionType=GameCollisionTypes.DynamicObject,
        shapeFilter = GameShapeFilters.DynamicObject
      )[1] # get shape from tuple
    )

  for obj in state.level.dynamicCircles:
    state.dynamicObjectShapes.add(
      state.space.addCircle(
        obj.position, obj.radius, 
        mass = obj.mass,
        friction = obj.friction,
        collisionType=GameCollisionTypes.DynamicObject,
        shapeFilter = GameShapeFilters.DynamicObject
      )[1] # get shape from tuple
    )

proc drawCircle*(camera: Camera, pos: Vect, radius: float, angle: float, color: LCDColor) =
  # covert from center position to top left
  let drawPos = pos - camera
  let x = (drawPos.x - radius).toInt
  let y = (drawPos.y - radius).toInt
  let size: int = (radius * 2f).toInt
  # angle is in radians, convert to degrees
  let deg = radTodeg(angle)
  gfx.drawEllipse(x,y,size, size, 1, deg+10, deg + 350, color);

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
    elif shape.kind == cpCircleShape:
      let circle = cast[CircleShape](shape)
      drawCircle(camera, circle.body.position + circle.offset, circle.radius, circle.body.angle, kColorBlack)
    else:
      print "drawDynamicObjects: Unknown shape kind: ", shape.kind

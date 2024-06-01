import std/math
import chipmunk7
import screens/game/game_types

proc transform*(v1:Vect, dir: DriveDirection): Vect {.inline.} =
  result = v(v1.x * dir, v1.y)

proc transform*(v1: Vect, v2: Vect): Vect {.inline.} =
  result = v(v1.x * v2.x, v1.y * v2.y)

proc flip*(v1:Vect): Vect {.inline.} =
  result = v(-v1.x, v1.y)

proc round*(v: Vect): Vect {.inline.} =
  result = v(v.x.round, v.y.round)

proc floor*(v: Vect): Vect {.inline.} =
  result = v(v.x.floor, v.y.floor)

proc `/`*(v: Vect, s: Float): Vect {.inline.} =
  result = v(v.x / s, v.y / s)

proc area*(v: SizeF): float32 {.inline.} =
  result = v.x * v.y

proc flip*(body: Body, relativeTo: Body) {.inline.} =
  ## Flip body horizontally relative to relativeTo
  body.angle = relativeTo.angle + (relativeTo.angle - body.angle)
  body.position = localToWorld(relativeTo, worldToLocal(relativeTo, body.position).transform(-1.0))

proc addBox*(
  space: Space, pos: Vect, size: Vect, mass: float32, angle: float32 = 0f, friction = 0f,
  collisionType: GameCollisionType = GameCollisionTypes.None, shapeFilter = SHAPE_FILTER_NONE
  ) : (Body, Shape) =
    let body = space.addBody(
        newBody(mass, momentForBox(mass, size.x, size.y))
    )
    body.position = pos
    body.angle = angle

    if shapeFilter != SHAPE_FILTER_NONE or defined(debug):
      let shape = space.addShape(newBoxShape(body, size.x, size.y, 0f))
      shape.filter = shapeFilter
      shape.collisionType = collisionType
      shape.friction = friction
      return (body, shape)
    else:
      return (body, nil)

proc addCircle*(
  space: Space, pos: Vect, radius: float32, mass: float32, angle: float32 = 0f, friction = 0f,
  collisionType: GameCollisionType = GameCollisionTypes.None, shapeFilter = SHAPE_FILTER_NONE
  ) : (Body, Shape) =
    let body = space.addBody(
        newBody(mass, momentForCircle(mass, 0f, radius, vzero))
    )
    body.position = pos
    body.angle = angle

    if shapeFilter != SHAPE_FILTER_NONE or defined(debug):
      let shape = space.addShape(newCircleShape(body, radius, vzero))
      shape.filter = shapeFilter
      shape.collisionType = collisionType
      shape.friction = friction
      return (body, shape)

    return (body, nil)

import std/math
import utils
import chipmunk7
import game/game_types

proc transform*(v1:Vect, dir: DriveDirection): Vect =
  result = v(v1.x * dir, v1.y)

proc flip*(v1:Vect): Vect =
  result = v(-v1.x, v1.y)

proc round*(v: Vect): Vect =
  result = v(v.x.round, v.y.round)

proc floor*(v: Vect): Vect =
  result = v(v.x.floor, v.y.floor)

proc flip*(body: Body, relativeTo: Body) =
  ## Flip body horizontally relative to relativeTo
  body.angle = relativeTo.angle + (relativeTo.angle - body.angle)
  body.position = localToWorld(relativeTo, worldToLocal(relativeTo, body.position).transform(-1.0))

proc addBox*(space: Space, pos: Vect, size: Vect, mass: float32, angle: float32 = 0f, shapeStore: var seq[Shape]) : Body =
    let body = space.addBody(
        newBody(mass, momentForBox(mass, size.x, size.y))
    )
    body.position = pos
    body.angle = angle

    let shape = space.addShape(newBoxShape(body, size.x, size.y, 0f))
    shape.filter = SHAPE_FILTER_NONE # no collisions
    shapeStore.add(shape)

    return body

proc addCircle*(
  space: Space, pos: Vect, radius: float32, mass: float32, angle: float32 = 0f, 
  collisionType: GameCollisionType = GameCollisionTypes.None, shapeFilter = SHAPE_FILTER_NONE) : Body =
    let body = space.addBody(
        newBody(mass, momentForCircle(mass, 0f, radius, vzero))
    )
    body.position = pos
    body.angle = angle

    let shape = space.addShape(newCircleShape(body, radius, vzero))
    shape.filter = shapeFilter
    shape.collisionType = collisionType

    return body

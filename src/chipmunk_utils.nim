import chipmunk7

proc addBox*(space: Space, pos: Vect, size: Vect, mass: float32, angle: float32 = 0f) : Body =
    let body = space.addBody(
        newBody(mass, momentForBox(mass, size.x, size.y))
    )
    body.position = pos
    body.angle = angle

    let shape = space.addShape(newBoxShape(body, size.x, size.y, 0f))
    shape.filter = SHAPE_FILTER_NONE # no collisions

    return body

proc addCircle*(space: Space, pos: Vect, radius: float32, mass: float32) : Body =
    let body = space.addBody(
        newBody(mass, momentForCircle(mass, 0f, radius, vzero))
    )
    body.position = pos

    let shape = space.addShape(newCircleShape(body, radius, vzero))
    shape.filter = SHAPE_FILTER_NONE # no collisions

    return body
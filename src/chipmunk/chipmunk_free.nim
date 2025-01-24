import chipmunk7
import common/utils

let shapeFreeWrap: PostStepFunc = proc (space: Space, shapePtr: pointer, unused: pointer) {.cdecl.} =
  let shape = cast[Shape](shapePtr)
  space.removeShape(shape)
  shape.destroy()

proc postShapeFree*(shape: Shape, data: pointer) {.cdecl.} =
  let space = cast[Space](data)
  discard space.addPostStepCallback(shapeFreeWrap, shape, nil)

let constraintFreeWrap: PostStepFunc = proc (space: Space, constraintPtr: pointer, unused: pointer) {.cdecl.} =
  let constraint = cast[Constraint](constraintPtr)
  space.removeConstraint(constraint)
  constraint.destroy()

proc postConstraintFree*(constraint: Constraint, data: pointer) {.cdecl.} =
  let space = cast[Space](data)
  discard space.addPostStepCallback(constraintFreeWrap, constraint, nil)

let bodyFreeWrap: PostStepFunc = proc (space: Space, bodyPtr: pointer, unused: pointer) {.cdecl.} =
  let body = cast[Body](bodyPtr)
  space.removeBody(body)
  body.destroy()

proc postBodyFree*(body: Body, data: pointer) {.cdecl.} =
  let space = cast[Space](data)
  discard space.addPostStepCallback(bodyFreeWrap, body, nil)

proc freeSpaceChildren*(space: Space) =
  markStartTime()
  space.eachShape(postShapeFree, space)
  space.eachConstraint(postConstraintFree, space)
  space.eachBody(postBodyFree, space)
  printT("Freeing space children.")
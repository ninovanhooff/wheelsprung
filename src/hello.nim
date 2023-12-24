import std/math
import chipmunk7
import strutils
import playdate/api


var gravity = v(0, 100)
const brakeTorque = 3_000f
var timeStep = 1.0/50.0
var time = 0.0

var space = newSpace()
space.gravity = gravity
# space.iterations = 1

proc print(str: auto) =
  playdate.system.logToConsole(str)

proc addWheel(space: Space, pos: Vect): Body =
  var radius = 15.0f
  var mass = 1.0f

  var moment = momentForCircle(mass, 0, radius, vzero)

  var body = space.addBody(newBody(mass, moment))
  body.position = pos

  var shape = space.addShape(newCircleShape(body, radius, vzero))
  shape.friction = 1.0f

  return body

proc addChassis(space: Space, pos: Vect): Body =
  var mass = 5.0f
  var width = 80.0f
  var height = 30.0f

  var moment = momentForBox(mass, width, height)

  var body = space.addBody(newBody(mass, moment))
  body.position = pos

  var shape = space.addShape(newBoxShape(body, width, height, 0f))
  shape.elasticity = 0.0f
  shape.friction = 0.7f

  return body

proc rad2deg(rad: float): float =
  return rad * 180.0 / PI

proc drawCircle(pos: Vect, radius: float, angle:float, color: LCDColor) =
  # covert from center position to top left
  let x = (pos.x - radius).toInt
  let y = (pos.y - radius).toInt
  let size: int = (radius * 2f).toInt
  # angle is in radians, convert to degrees
  let deg = rad2deg(angle)
  playdate.graphics.drawEllipse(x,y,size, size, 1, deg, deg + 350, color);

proc drawSegment(segment: SegmentShape, color: LCDColor) =
  playdate.graphics.drawLine(segment.a.x.toInt, segment.a.y.toInt, segment.b.x.toInt, segment.b.y.toInt, 1, color);

proc shapeIter(shape: Shape, data: pointer) {.cdecl.} =
    if shape.kind == cpCircleShape:
      let circle = cast[CircleShape](shape)
      drawCircle(circle.body.position, circle.radius, circle.body.angle, kColorBlack)
    elif shape.kind == cpSegmentShape:
      let segment = cast[SegmentShape](shape)
      drawSegment(segment, kColorBlack)
    elif shape.kind == cpPolyShape:
      let poly = cast[PolyShape](shape)
      let numVerts = poly.count
      for i in 0 ..< numVerts:
        let a = localToWorld(poly.body, poly.vert(i))
        let b = localToWorld(poly.body, poly.vert((i+1) mod numVerts))
        playdate.graphics.drawLine(a.x.toInt, a.y.toInt, b.x.toInt, b.y.toInt, 1, kColorBlack);

proc constraintIter(constraint: Constraint, data: pointer) {.cdecl.} =
  if constraint.isGrooveJoint:
    # discard
    let groove = cast[GrooveJoint](constraint)
    let a = localToWorld(groove.bodyA, groove.grooveA)
    let b = localToWorld(groove.bodyA, groove.grooveB)
    playdate.graphics.drawLine(a.x.toInt, a.y.toInt, b.x.toInt, b.y.toInt, 1, kColorBlack);
  elif constraint.isDampedSpring:
    let spring = cast[DampedSpring](constraint)
    let a = localToWorld(spring.bodyA, spring.anchorA)
    let b = localToWorld(spring.bodyB, spring.anchorB)
    playdate.graphics.drawLine(a.x.toInt, a.y.toInt, b.x.toInt, b.y.toInt, 1, kColorBlack);

proc drawChipmunkHello*() =
  # iterate over all shapes in the space
  eachShape(space, shapeIter, nil)
  eachConstraint(space, constraintIter, nil)

let
  posA = v(50, 60)
  posB = v(110, 60)
  posChassis = v(80, 20)


var ground = newSegmentShape(space.staticBody, v(20, 150), v(240, 150), 0)
ground.friction = 3.0
discard space.addShape(ground)

let wheel1: Body = space.addWheel(posA)
let wheel2: Body = addWheel(space, posB)
let chassis: Body = addChassis(space, posChassis)

# NOTE inverted y axis!
discard space.addConstraint(
  chassis.newGrooveJoint(wheel1, v(-30, 10), v(-30, 40), vzero)
)
discard space.addConstraint(
  chassis.newGrooveJoint(wheel2, v(30, 10), v(30, 40), vzero)
)

discard space.addConstraint(
  chassis.newDampedSpring(wheel1, v(-30,0), vzero, 50f, 20f, 10f)
)
discard space.addConstraint(
  chassis.newDampedSpring(wheel2, v(30,0), vzero, 50f, 20f, 10f)
)

proc resetPosition() =
  wheel1.position = posA
  wheel1.velocity = vzero
  wheel1.force = vzero
  wheel1.angle = 0f
  wheel1.angularVelocity = 0f
  wheel1.torque = 0f

  wheel2.position = posB
  wheel2.velocity = vzero
  wheel2.force = vzero
  wheel2.angle = 0f
  wheel2.angularVelocity = 0f
  wheel2.torque = 0f

  chassis.position = posChassis
  chassis.velocity = vzero
  chassis.force = vzero
  chassis.angle = 0f
  chassis.angularVelocity = 0f
  chassis.torque = 0f

proc onThrottle*() =
  wheel1.torque = 10000f
  print("wheel1.torque: " & $wheel1.torque)

proc onBrake*() =
  wheel1.torque = -wheel1.angularVelocity * brakeTorque
  wheel2.torque = -wheel2.angularVelocity * brakeTorque
  print("wheel1.torque: " & $wheel1.torque)
  print("wheel2.torque: " & $wheel2.torque)

proc updateChipmunkHello*() {.cdecl, raises: [].} =
# playdate is the global PlaydateAPI instance, available when playdate/api is imported
  let buttonsState = playdate.system.getButtonsState()

  if kButtonUp in buttonsState.current:
    playdate.system.logToConsole("Button UP held")
    onThrottle()
  elif kButtonDown in buttonsState.current:
    playdate.system.logToConsole("Button DOWN held")
    onBrake()
  elif kButtonLeft in buttonsState.pushed:
    playdate.system.logToConsole("Button Left pressed")
    resetPosition()

  space.step(timeStep)
  time += timeStep


when defined chipmunkNoDestructors:
  ballShape.destroy()
  ballBody.destroy()
  ground.destroy()
  space.destroy()
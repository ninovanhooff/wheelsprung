import std/math
import chipmunk7
import playdate/api
import levels


var gravity = v(0, 100)
const attitudeAdjustTorque = 450_000f
const brakeTorque = 5_000f
const wheelFriction = 3.0f
var timeStep = 1.0/50.0
var time = 0.0

var space: Space
var wheel1: Body
var wheel2: Body
var chassis: Body
var swingArm: Body
var observedConstraint: Constraint

let
  wheelRadius = 15.0f
  posA = v(30, 30)
  posB = v(110, 60)
  posChassis = v(80, 20)
  swingArmWidth = 40f
  swingArmHeight = 5f
  swingArmPosOffset = v(-30,10)
  swingArmRestAngle = 0f

var camera: Vect = vzero

proc print(str: auto) =
  playdate.system.logToConsole($str)

proc addWheel(space: Space, pos: Vect): Body =
  var radius = wheelRadius
  var mass = 1.0f

  var moment = momentForCircle(mass, 0, radius, vzero)

  var body = space.addBody(newBody(mass, moment))
  body.position = pos

  var shape = space.addShape(newCircleShape(body, radius, vzero))
  shape.friction = wheelFriction

  return body

proc addChassis(space: Space, pos: Vect): Body =
  var mass = 4.0f
  var width = 80.0f
  var height = 30.0f

  var moment = momentForBox(mass, width, height)

  var body = space.addBody(newBody(mass, moment))
  body.position = pos

  var shape = space.addShape(newBoxShape(body, width, height, 0f))
  shape.filter = SHAPE_FILTER_NONE # no collisions
  shape.elasticity = 0.0f
  shape.friction = 0.7f

  return body

proc addSwingArm(space: Space, pos: Vect): Body =
  let swingArmMmass = 0.5f
  let swingArmWidth = swingArmWidth
  let swingArmHeight = swingArmHeight

  let swingArmMoment = momentForBox(swingArmMmass, swingArmWidth, swingArmHeight)
  let swingArm = space.addBody(newBody(swingArmMmass, swingArmMoment))
  swingArm.position = pos
  swingArm.angle = swingArmRestAngle

  let swingArmShape = space.addShape(newBoxShape(swingArm, swingArmWidth, swingArmHeight, 0f))
  swingArmShape.filter = SHAPE_FILTER_NONE # no collisions
  swingArmShape.elasticity = 0.0f
  swingArmShape.friction = 0.7f

  return swingArm

proc rad2deg(rad: float): float =
  return rad * 180.0 / PI

proc drawCircle(pos: Vect, radius: float, angle:float, color: LCDColor) =
  # covert from center position to top left
  let drawPos = pos - camera
  let x = (drawPos.x - radius).toInt
  let y = (drawPos.y - radius).toInt
  let size: int = (radius * 2f).toInt
  # angle is in radians, convert to degrees
  let deg = rad2deg(angle)
  playdate.graphics.drawEllipse(x,y,size, size, 1, deg, deg + 350, color);

proc drawSegment(segment: SegmentShape, color: LCDColor) =
  let drawAPos = segment.a - camera
  let drawBPos = segment.b - camera
  playdate.graphics.drawLine(drawAPos.x.toInt, drawAPos.y.toInt, drawBPos.x.toInt, drawBPos.y.toInt, 1, color);

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
        let a = localToWorld(poly.body, poly.vert(i)) - camera
        let b = localToWorld(poly.body, poly.vert((i+1) mod numVerts)) - camera
        playdate.graphics.drawLine(a.x.toInt, a.y.toInt, b.x.toInt, b.y.toInt, 1, kColorBlack);

proc constraintIter(constraint: Constraint, data: pointer) {.cdecl.} =
  if constraint.isGrooveJoint:
    # discard
    let groove = cast[GrooveJoint](constraint)
    let a = localToWorld(groove.bodyA, groove.grooveA) - camera
    let b = localToWorld(groove.bodyA, groove.grooveB) - camera
    playdate.graphics.drawLine(a.x.toInt, a.y.toInt, b.x.toInt, b.y.toInt, 1, kColorBlack);
  elif constraint.isDampedSpring:
    let spring = cast[DampedSpring](constraint)
    let a = localToWorld(spring.bodyA, spring.anchorA) - camera
    let b = localToWorld(spring.bodyB, spring.anchorB) - camera
    playdate.graphics.drawLine(a.x.toInt, a.y.toInt, b.x.toInt, b.y.toInt, 1, kColorBlack);
  elif constraint.isDampedRotarySpring:
    let spring = cast[DampedRotarySpring](constraint)
    let a = localToWorld(spring.bodyA, vzero) - camera
    let b = localToWorld(spring.bodyB, vzero) - camera
    playdate.graphics.drawLine(a.x.toInt, a.y.toInt, b.x.toInt, b.y.toInt, 1, kColorBlack);

proc drawChipmunkHello*() =
  # iterate over all shapes in the space
  eachShape(space, shapeIter, nil)
  eachConstraint(space, constraintIter, nil)

proc initHello*() {.raises: [].} =
  space = loadLevel("levels/fallbackLevel.json")
  space.gravity = gravity
  wheel1 = space.addWheel(posA)
  wheel2 = space.addWheel(posB)
  chassis = space.addChassis(posChassis)
  swingArm = space.addSwingArm(posChassis + swingArmPosOffset)

  # NOTE inverted y axis!
  let swingArmEndCenter = v(swingArmWidth*0.5f, swingArmHeight*0.5f)
  # attach swing arm to chassis
  discard space.addConstraint(
    chassis.newPivotJoint(
      swingArm, 
      swingArmPosOffset + swingArmEndCenter, 
      swingArmEndCenter
    )
  )

  # limit wheel to swing arm
  discard space.addConstraint(
    swingArm.newGrooveJoint(
      wheel1, 
      v(-swingArmWidth*2f, swingArmHeight*0.5f), 
      vzero, vzero
    )
  )
  # push wheel to end of swing arm
  discard space.addConstraint(
    swingArm.newDampedSpring(wheel1, swingArmEndCenter, vzero, swingArmWidth, 100f, 20f)
  )
  
  # # push swing arm down from chassis
  # discard space.addConstraint(
  #   chassis.newDampedSpring(swingArm, swingArmPosOffset + v(0, -20f), vzero, 30f, 40f, 50f)
  # )

  # observedConstraint = space.addConstraint(
  #   swingArm.newRotaryLimitJoint(chassis, -0.5f, 0.5f)
  # )
  observedConstraint = space.addConstraint(
    chassis.newDampedRotarySpring(swingArm, 0.2f*PI, 30_000f, 4_000f)
  )

  # wheel 2
  discard space.addConstraint(
    chassis.newGrooveJoint(wheel2, v(30, 10), v(30, 80), vzero)
  )
  discard space.addConstraint(
    chassis.newDampedSpring(wheel2, v(30,0), vzero, 40f, 20f, 10f)
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

proc onAttitudeAdjust(direction: float) =
  chassis.torque = direction * attitudeAdjustTorque
  print("chassis.torque: " & $chassis.torque)

proc handleInput() =
    let buttonsState = playdate.system.getButtonsState()

    if kButtonUp in buttonsState.current:
      playdate.system.logToConsole("Button UP held")
      onThrottle()
    elif kButtonDown in buttonsState.current:
      playdate.system.logToConsole("Button DOWN held")
      onBrake()
    elif kButtonLeft in buttonsState.pushed:
      playdate.system.logToConsole("Button Left pressed")
      onAttitudeAdjust(-1f)
    elif kButtonRight in buttonsState.pushed:
      playdate.system.logToConsole("Button Right pressed")
      onAttitudeAdjust(1f)

proc updateChipmunkHello*() {.cdecl, raises: [].} =
  handleInput()

  space.step(timeStep)
  time += timeStep

  camera = chassis.position - v(playdate.display.getWidth()/2, playdate.display.getHeight()/2)


when defined chipmunkNoDestructors:
  ballShape.destroy()
  ballBody.destroy()
  ground.destroy()
  space.destroy()
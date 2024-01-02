import std/math
import chipmunk7
import playdate/api
import levels
import bike_engine

const
  gravity = v(0, 100)
  initialAttitudeAdjustTorque = 50_000f
  attitudeAdjustAttentuation = 0.8f
  attitudeAdjustForceThreshold = 100f
  maxWheelAngularVelocity = 50f
  # applied to wheel1 and chassis to make bike more unstable
  throttleTorque = 2_000f
  # applied to both wheels
  brakeTorque = 2_000f
  wheelFriction = 3.0f
  timeStep = 1.0f/50.0f

var space: Space
var backWheel: Body
var frontWheel: Body
var chassis: Body
var swingArm: Body
var forkArm: Body

var actionThrottle = kButtonUp
if defined device:
  actionThrottle = kButtonA
var actionBrake = kButtonDown
if defined device:
  actionBrake = kButtonB

let
  wheelRadius = 10.0f
  posChassis = v(80, 20)
  posA = v(posChassis.x - 20, posChassis.y + 10)
  posB = v(posChassis.x + 21, posChassis.y + 12)
  
  swingArmWidth = 20f
  swingArmHeight = 3f
  swingArmPosOffset = v(-10,10)
  swingArmRestAngle = 0f

  forkArmWidth = 3f
  forkArmHeight = 25f
  forkArmPosOffset = v(16,2)
  forkArmRestAngle = 0f#-0.1f*PI

var 
  time = 0.0
  camera: Vect = vzero
  attitudeAdjustForce = 0f

proc print(str: auto) =
  playdate.system.logToConsole($str)

proc addWheel(space: Space, pos: Vect): Body =
  var radius = wheelRadius
  var mass = 0.6f

  var moment = momentForCircle(mass, 0, radius, vzero)

  var body = space.addBody(newBody(mass, moment))
  body.position = pos

  var shape = space.addShape(newCircleShape(body, radius, vzero))
  shape.friction = wheelFriction

  return body

proc addChassis(space: Space, pos: Vect): Body =
  var mass = 1.0f
  var width = 34f
  var height = 20.0f

  var moment = momentForBox(mass, width, height)

  var body = space.addBody(newBody(mass, moment))
  body.position = pos

  var shape = space.addShape(newBoxShape(body, width, height, 0f))
  shape.filter = SHAPE_FILTER_NONE # no collisions
  shape.elasticity = 0.0f
  shape.friction = 0.7f

  return body

proc addSwingArm(space: Space, pos: Vect): Body =
  let swingArmMmass = 0.25f
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

proc addForkArm(space: Space, pos: Vect): Body =
  let forkArmMmass = 0.25f
  let forkArmWidth = forkArmWidth
  let forkArmHeight = forkArmHeight

  let forkArmMoment = momentForBox(forkArmMmass, forkArmWidth, forkArmHeight)
  let forkArm = space.addBody(newBody(forkArmMmass, forkArmMoment))
  forkArm.position = pos
  forkArm.angle = forkArmRestAngle

  let forkArmShape = space.addShape(newBoxShape(forkArm, forkArmWidth, forkArmHeight, 0f))
  forkArmShape.filter = SHAPE_FILTER_NONE # no collisions
  forkArmShape.elasticity = 0.0f
  forkArmShape.friction = 0.7f

  return forkArm

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

proc setConstraints() =
  # NOTE inverted y axis!

  # SwingArm (arm between chassis and rear wheel)
  let swingArmEndCenter = v(swingArmWidth*0.5f, swingArmHeight*0.5f)
  # attach swing arm to chassis
  discard space.addConstraint(
    chassis.newPivotJoint(
      swingArm, 
      swingArmPosOffset + swingArmEndCenter, 
      swingArmEndCenter
    )
  )

  # limit wheel1 to swing arm
  discard space.addConstraint(
    swingArm.newGrooveJoint(
      backWheel, 
      v(-swingArmWidth*2f, swingArmHeight*0.5f), 
      vzero, 
      vzero
    )
  )
  # push wheel1 to end of swing arm
  discard space.addConstraint(
    swingArm.newDampedSpring(backWheel, swingArmEndCenter, vzero, swingArmWidth, 40f, 10f)
  )

  discard space.addConstraint(
    chassis.newDampedRotarySpring(swingArm, 0.1f*PI, 30_000f, 4_000f) # todo rest angle?
  )

  # fork arm (arm between chassis and front wheel)

  let forkArmTopCenter = v(0f, -forkArmHeight*0.5f)
  # let forkArmEndCenter = v(forkArmWidth*0.5f, forkArmHeight*0.5f)
  # attach swing arm to chassis
  discard space.addConstraint(
    chassis.newPivotJoint(
      forkArm, 
      forkArmPosOffset + forkArmTopCenter, 
      forkArmTopCenter
    )
  )
  # limit wheel2 to fork arm
  discard space.addConstraint(
    forkArm.newGrooveJoint(
      frontWheel, 
      vzero,
      v(0f, forkArmHeight), 
      vzero
    )
  )
  # push wheel2 to end of fork arm
  discard space.addConstraint(
    forkArm.newDampedSpring(frontWheel, forkArmTopCenter, vzero, forkArmHeight, 100f, 20f)
  )

  discard space.addConstraint(
    chassis.newDampedRotarySpring(forkArm, 0.1f*PI, 10_000f, 2000f) # todo rest angle?
  )

proc initHello*() {.raises: [].} =
  space = loadLevel("levels/fallbackLevel.json")
  space.gravity = gravity
  backWheel = space.addWheel(posA)
  frontWheel = space.addWheel(posB)
  chassis = space.addChassis(posChassis)
  swingArm = space.addSwingArm(posChassis + swingArmPosOffset)
  forkArm = space.addForkArm(posChassis + forkArmPosOffset)
  setConstraints()
  initBikeEngine()

# proc resetPosition() =
#   wheel1.position = posA
#   wheel1.velocity = vzero
#   wheel1.force = vzero
#   wheel1.angle = 0f
#   wheel1.angularVelocity = 0f
#   wheel1.torque = 0f

#   wheel2.position = posB
#   wheel2.velocity = vzero
#   wheel2.force = vzero
#   wheel2.angle = 0f
#   wheel2.angularVelocity = 0f
#   wheel2.torque = 0f

#   chassis.position = posChassis
#   chassis.velocity = vzero
#   chassis.force = vzero
#   chassis.angle = 0f
#   chassis.angularVelocity = 0f
#   chassis.torque = 0f

proc onThrottle*() =
  if backWheel.angularVelocity > maxWheelAngularVelocity:
    print("ignore throttle. back wheel already at max angular velocity")
    return

  backWheel.torque = throttleTorque
  chassis.torque = chassis.torque - throttleTorque * 2f
  print("wheel1.torque: " & $backWheel.torque)

proc onBrake*() =
  backWheel.torque = -backWheel.angularVelocity * brakeTorque
  frontWheel.torque = -frontWheel.angularVelocity * brakeTorque
  print("wheel1.torque: " & $backWheel.torque)
  print("wheel2.torque: " & $frontWheel.torque)

proc updateAttitudeAdjust() =
  if attitudeAdjustForce != 0f:
    chassis.torque = attitudeAdjustForce
    attitudeAdjustForce *= attitudeAdjustAttentuation
    if attitudeAdjustForce.abs < attitudeAdjustForceThreshold:
      attitudeAdjustForce = 0f

proc onAttitudeAdjust(direction: float) =
  if attitudeAdjustForce == 0f:
    attitudeAdjustForce = direction * initialAttitudeAdjustTorque
  else:
    print("ignore attitude adjust. Already in progress with remaining force: " & $attitudeAdjustForce)
    

proc handleInput() =
    let buttonsState = playdate.system.getButtonsState()

    if actionThrottle in buttonsState.current:
      playdate.system.logToConsole("Button UP held")
      onThrottle()
    if actionBrake in buttonsState.current:
      playdate.system.logToConsole("Button DOWN held")
      onBrake()
    
    if kButtonLeft in buttonsState.pushed:
      playdate.system.logToConsole("Button Left pressed")
      onAttitudeAdjust(-1f)
    elif kButtonRight in buttonsState.pushed:
      playdate.system.logToConsole("Button Right pressed")
      onAttitudeAdjust(1f)

proc updateChipmunkHello*() {.cdecl, raises: [].} =
  handleInput()
  updateAttitudeAdjust()

  space.step(timeStep)
  time += timeStep

  camera = chassis.position - v(playdate.display.getWidth()/2, playdate.display.getHeight()/2)


when defined chipmunkNoDestructors:
  ballShape.destroy()
  ballBody.destroy()
  ground.destroy()
  space.destroy()
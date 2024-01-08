import std/math
import chipmunk7
import playdate/api
import utils
import levels
import bike_engine
import game_types
import game_view

const
  gravity = v(0, 100)
  initialAttitudeAdjustTorque = 50_000f
  attitudeAdjustAttentuation = 0.8f
  attitudeAdjustForceThreshold = 100f
  maxWheelAngularVelocity = 100f
  # applied to wheel1 and chassis to make bike more unstable
  throttleTorque = 2_000f
  # applied to both wheels
  brakeTorque = 2_000f
  wheelFriction = 3.0f
  timeStep = 1.0f/50.0f

var state: GameState
var backWheel: Body
var frontWheel: Body
var chassis: Body
var swingArm: Body
var forkArm: Body
var isThrottlePressed = false

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

proc setConstraints(space: Space) =
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

proc initGame*() {.raises: [].} =
  let space = loadLevel("levels/fallbackLevel.json")
  state = GameState(space: space)
  space.gravity = gravity
  backWheel = space.addWheel(posA)
  frontWheel = space.addWheel(posB)
  chassis = space.addChassis(posChassis)
  swingArm = space.addSwingArm(posChassis + swingArmPosOffset)
  forkArm = space.addForkArm(posChassis + forkArmPosOffset)
  space.setConstraints()
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
  print("wheel1.torque: " & $backWheel.torque)

proc onBrake*() =
  backWheel.torque = -backWheel.angularVelocity * brakeTorque
  frontWheel.torque = -frontWheel.angularVelocity * brakeTorque
  print("wheel1.torque: " & $backWheel.torque)
  print("wheel2.torque: " & $frontWheel.torque)

proc updateAttitudeAdjust(state: GameState) =
  if state.attitudeAdjustForce != 0f:
    chassis.torque = state.attitudeAdjustForce
    state.attitudeAdjustForce *= attitudeAdjustAttentuation
    if state.attitudeAdjustForce.abs < attitudeAdjustForceThreshold:
      state.attitudeAdjustForce = 0f

proc onAttitudeAdjust(state: GameState, direction: float) =
  if state.attitudeAdjustForce == 0f:
    state.attitudeAdjustForce = direction * initialAttitudeAdjustTorque
  else:
    print("ignore attitude adjust. Already in progress with remaining force: " & $state.attitudeAdjustForce)
    

proc handleInput() =
    isThrottlePressed = false

    let buttonsState = playdate.system.getButtonsState()

    if actionThrottle in buttonsState.current:
      playdate.system.logToConsole("Button UP held")
      isThrottlePressed = true
      onThrottle()
    if actionBrake in buttonsState.current:
      playdate.system.logToConsole("Button DOWN held")
      onBrake()
    
    if kButtonLeft in buttonsState.pushed:
      playdate.system.logToConsole("Button Left pressed")
      state.onAttitudeAdjust(-1f)
    elif kButtonRight in buttonsState.pushed:
      playdate.system.logToConsole("Button Right pressed")
      state.onAttitudeAdjust(1f)

proc updateChipmunkGame*() {.cdecl, raises: [].} =
  handleInput()
  state.updateAttitudeAdjust()

  state.space.step(timeStep)
  state.time += timeStep

  updateBikeEngine(isThrottlePressed, frontWheel.angularVelocity)

  state.camera = chassis.position - v(playdate.display.getWidth()/2, playdate.display.getHeight()/2)
  drawChipmunkGame(addr state)

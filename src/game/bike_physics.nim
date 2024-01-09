import chipmunk7
import std/math
import game_types

let
  # offset for driveDirection DD_RIGHT
  wheelRadius = 10.0f
  wheelFriction = 3.0f
  initialChassisPos = v(80, 20)
  backWheelOffset = v(-20, 10)
  frontWheelOffset = v(21, 12)
  
  swingArmWidth = 20f
  swingArmHeight = 3f
  swingArmPosOffset = v(-10,10)

  forkArmWidth = 3f
  forkArmHeight = 25f
  forkArmPosOffset = v(16,2)
  forkArmRestAngle = 0f#-0.1f*PI

# proc transformDriveDirection*(dir: DriveDirection): Vect =
#   case dir
#   of DD_RIGHT: return v(1, 1)
#   of DD_LEFT: return v(-1, 1)

proc transform(v1:Vect, dir: DriveDirection): Vect =
  result = v(v1.x * dir, v1.y)

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
  let swingArmMass = 0.25f
  let swingArmWidth = swingArmWidth
  let swingArmHeight = swingArmHeight

  let swingArmMoment = momentForBox(swingArmMass, swingArmWidth, swingArmHeight)
  let swingArm = space.addBody(newBody(swingArmMass, swingArmMoment))
  swingArm.position = pos

  # let swingArmShape = space.addShape(newBoxShape(swingArm, swingArmWidth, swingArmHeight, 0f))
  # swingArmShape.filter = SHAPE_FILTER_NONE # no collisions
  # swingArmShape.elasticity = 0.0f
  # swingArmShape.friction = 0.7f

  return swingArm

proc addForkArm(space: Space, pos: Vect): Body =
  let forkArmMmass = 0.25f
  let forkArmWidth = forkArmWidth
  let forkArmHeight = forkArmHeight

  let forkArmMoment = momentForBox(forkArmMmass, forkArmWidth, forkArmHeight)
  let forkArm = space.addBody(newBody(forkArmMmass, forkArmMoment))
  forkArm.position = pos
  forkArm.angle = forkArmRestAngle

  # let forkArmShape = space.addShape(newBoxShape(forkArm, forkArmWidth, forkArmHeight, 0f))
  # forkArmShape.filter = SHAPE_FILTER_NONE # no collisions
  # forkArmShape.elasticity = 0.0f
  # forkArmShape.friction = 0.7f

  return forkArm

proc removeBikeConstraints(state: GameState) =
  let space = state.space

  for constraint in state.bikeConstraints:
    space.removeConstraint(constraint)
  state.bikeConstraints.setLen(0)

proc setBikeConstraints(state: GameState) =
  # NOTE inverted y axis!
  let space = state.space
  let dd = state.driveDirection
  let chassis = state.chassis
  let backWheel = state.backWheel
  let frontWheel = state.frontWheel
  let swingArm = state.swingArm
  let forkArm = state.forkArm
  var bikeConstraints: seq[Constraint] = state.bikeConstraints

  # SwingArm (arm between chassis and rear wheel)
  let swingArmEndCenter = v(swingArmWidth*0.5f*dd, swingArmHeight*0.5f)
  # attach swing arm to chassis
  bikeConstraints.add(space.addConstraint(
    chassis.newPivotJoint(
      swingArm, 
      swingArmPosOffset.transform(dd) + swingArmEndCenter, 
      swingArmEndCenter
    )
  ))

  # limit wheel1 to swing arm
  bikeConstraints.add(space.addConstraint(
    chassis.newPivotJoint(
      swingArm, 
      swingArmPosOffset.transform(dd) + swingArmEndCenter, 
      swingArmEndCenter
    )
  ))
  
  bikeConstraints.add(space.addConstraint(
    swingArm.newGrooveJoint(
      backWheel, 
      v(-swingArmWidth*2f*dd, swingArmHeight*0.5f), 
      vzero, 
      vzero
    )
  ))
  # push wheel1 to end of swing arm
  bikeConstraints.add(space.addConstraint(
    swingArm.newDampedSpring(backWheel, swingArmEndCenter, vzero, swingArmWidth, 40f, 10f)
  ))

  bikeConstraints.add(space.addConstraint(
    chassis.newDampedRotarySpring(swingArm, 0.1f*PI*dd, 30_000f, 4_000f) # todo rest angle?
  ))

  # fork arm (arm between chassis and front wheel)

  let forkArmTopCenter = v(0f, -forkArmHeight*0.5f)
  # let forkArmEndCenter = v(forkArmWidth*0.5f, forkArmHeight*0.5f)
  # attach swing arm to chassis
  bikeConstraints.add(space.addConstraint(
    chassis.newPivotJoint(
      forkArm, 
      forkArmPosOffset*dd + forkArmTopCenter, 
      forkArmTopCenter
    )
  ))
  # limit wheel2 to fork arm
  bikeConstraints.add(space.addConstraint(
    forkArm.newGrooveJoint(
      frontWheel, 
      vzero,
      v(0f, forkArmHeight), 
      vzero
    )
  ))
  # push wheel2 to end of fork arm
  bikeConstraints.add(space.addConstraint(
    forkArm.newDampedSpring(frontWheel, forkArmTopCenter, vzero, forkArmHeight, 100f, 20f)
  ))
  bikeConstraints.add(space.addConstraint(
    chassis.newDampedRotarySpring(forkArm, 0.1f*PI*dd, 10_000f, 2000f) # todo rest angle?
  ))

  state.bikeConstraints = bikeConstraints

proc flipDriveDirection*(state: GameState) =
  let space = state.space
  let chassisPos = state.chassis.position
  state.driveDirection = -state.driveDirection
  swap(state.backWheel, state.frontWheel)
  
  state.removeBikeConstraints()



  state.forkArm.angle = -state.forkArm.angle
  state.swingArm.angle = -state.swingArm.angle

  # space.removeBody(state.swingArm)
  # space.removeBody(state.forkArm)
  state.swingArm.position = chassisPos + swingArmPosOffset.transform(state.driveDirection)
  state.forkArm.position = chassisPos + forkArmPosOffset.transform(state.driveDirection)
  
  state.setBikeConstraints()

proc initBikePhysics*(state: GameState) =
  let space = state.space
  let dd = state.driveDirection

  state.chassis = space.addChassis(initialChassisPos)
  state.backWheel = space.addWheel(initialChassisPos + backWheelOffset.transform(dd))
  state.frontWheel = space.addWheel(initialChassisPos + frontWheelOffset.transform(dd))
  state.swingArm = space.addSwingArm(initialChassisPos + swingArmPosOffset.transform(dd))
  state.forkArm = space.addForkArm(initialChassisPos + forkArmPosOffset.transform(dd))
  
  state.setBikeConstraints()

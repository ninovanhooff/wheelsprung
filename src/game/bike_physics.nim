import chipmunk7
import std/math
import game_types
import chipmunk_utils

let
  # offset for driveDirection DD_RIGHT
  wheelRadius = 10.0f
  wheelFriction = 3.0f
  rearWheelOffset = v(-20, 10)
  frontWheelOffset = v(21, 12)
  
  swingArmWidth = 20f
  swingArmHeight = 3f
  swingArmPosOffset = v(-10,10)

  forkArmWidth = 3f
  forkArmHeight = 25f
  forkArmPosOffset = v(16,2)

proc addWheel(state: GameState, chassisOffset: Vect): Body =
  let space = state.space
  let radius = wheelRadius
  let mass = 0.6f

  let moment = momentForCircle(mass, 0, radius, vzero)

  let body = space.addBody(newBody(mass, moment))
  body.position = localToWorld(state.chassis, chassisOffset)

  let shape = space.addShape(newCircleShape(body, radius, vzero))
  shape.friction = wheelFriction

  return body

proc addChassis(space: Space, pos: Vect): Body =
  let mass = 1.0f
  let width = 34f
  let height = 20.0f

  let moment = momentForBox(mass, width, height)

  let body = space.addBody(newBody(mass, moment))
  body.position = pos

  # let shape = space.addShape(newBoxShape(body, width, height, 0f))
  # shape.filter = SHAPE_FILTER_NONE # no collisions

  return body

proc addSwingArm(state: GameState, chassisOffset: Vect): Body =
  let space = state.space
  let swingArmMass = 0.25f
  let swingArmWidth = swingArmWidth
  let swingArmHeight = swingArmHeight

  let swingArmMoment = momentForBox(swingArmMass, swingArmWidth, swingArmHeight)
  let swingArm = space.addBody(newBody(swingArmMass, swingArmMoment))
  swingArm.position = localToWorld(state.chassis, chassisOffset)
  swingArm.angle = state.chassis.angle

  # let swingArmShape = space.addShape(newBoxShape(swingArm, swingArmWidth, swingArmHeight, 0f))
  # swingArmShape.filter = SHAPE_FILTER_NONE # no collisions
  # swingArmShape.elasticity = 0.0f
  # swingArmShape.friction = 0.7f

  return swingArm

proc addForkArm(state: GameState, chassisOffset: Vect): Body =
  let space = state.space
  let forkArmMmass = 0.25f
  let forkArmWidth = forkArmWidth
  let forkArmHeight = forkArmHeight

  let forkArmMoment = momentForBox(forkArmMmass, forkArmWidth, forkArmHeight)
  let forkArm = space.addBody(newBody(forkArmMmass, forkArmMoment))
  forkArm.position = localToWorld(state.chassis, chassisOffset)
  forkArm.angle = state.chassis.angle

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
  let rearWheel = state.rearWheel
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

  # limit rearWheel to swing arm
  bikeConstraints.add(space.addConstraint(
    swingArm.newGrooveJoint(
      rearWheel, 
      v(-swingArmWidth*2f*dd, swingArmHeight*0.5f), 
      vzero, 
      vzero
    )
  ))
  # push wheel1 to end of swing arm
  bikeConstraints.add(space.addConstraint(
    swingArm.newDampedSpring(rearWheel, swingArmEndCenter, vzero, swingArmWidth, 40f, 10f)
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
      forkArmPosOffset.transform(dd) + forkArmTopCenter, 
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

proc flipBikeDirection*(state: GameState) =
  let space = state.space

  swap(state.rearWheel, state.frontWheel)
  
  state.removeBikeConstraints()
  
  space.removeBody(state.swingArm)
  space.removeBody(state.forkArm)
  state.swingArm = state.addSwingArm(swingArmPosOffset.transform(state.driveDirection))
  state.forkArm = state.addForkArm(forkArmPosOffset.transform(state.driveDirection))
  
  state.setBikeConstraints()

proc initBikePhysics*(state: GameState) =
  let space = state.space
  let dd = state.driveDirection

  state.chassis = space.addChassis(state.initialChassisPosition)
  state.rearWheel = state.addWheel(rearWheelOffset.transform(dd))
  state.frontWheel = state.addWheel(frontWheelOffset.transform(dd))
  state.swingArm = state.addSwingArm(swingArmPosOffset.transform(dd))
  state.forkArm = state.addForkArm(forkArmPosOffset.transform(dd))
  
  state.setBikeConstraints()

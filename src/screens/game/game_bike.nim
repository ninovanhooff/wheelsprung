import chipmunk7
import std/math
import game_types
import sound/bike_sound
import chipmunk_utils

const
  chassisMass = 1.5
  # note: collision shape smaller than texture (34x20)
  chassisWidth = 24.0
  chassisHeight = 12.0
  chassisFriction = 10.0


  # offset for driveDirection DD_RIGHT
  wheelRadius = 10.0
  wheelFriction = 30.0
  rearWheelOffset = v(-20, 10)
  frontWheelOffset = v(21, 12)
  
  swingArmWidth = 18.0
  halfSwingArmWidth* = swingArmWidth*0.5
  swingArmHeight = 3.0
  swingArmPosOffset = v(-10,10)

  forkArmWidth = 3.0
  forkArmHeight = 27.0
  forkArmPosOffset = v(16,2)
  forkArmTopCenterOffset* = v(0.0, -forkArmHeight*0.5)
  forkArmBottomCenterOffset* = v(0.0, forkArmHeight*0.5)


proc addWheel(state: GameState, chassisOffset: Vect): Body =
  let space = state.space
  let radius = wheelRadius
  let mass = 0.6f

  let moment = momentForCircle(mass, 0, radius, vzero)

  let body = space.addBody(newBody(mass, moment))
  body.position = localToWorld(state.chassis, chassisOffset)

  let shape = space.addShape(newCircleShape(body, radius, vzero))
  shape.filter = GameShapeFilters.Player
  shape.collision_type = GameCollisionTypes.Wheel
  shape.friction = wheelFriction
  state.bikeShapes.add(shape)

  return body

proc addChassis(state: GameState, pos: Vect): Body =
  let space = state.space

  let moment = momentForBox(chassisMass, chassisWidth, chassisHeight)

  let body = space.addBody(newBody(chassisMass, moment))
  body.position = pos

  return body

proc addChassisShape*(state: GameState): Shape =
  let space = state.space
  let chassis = state.chassis

  let shape = space.addShape(newBoxShape(chassis, chassisWidth, chassisHeight, 0f))
  shape.filter = GameShapeFilters.Player
  shape.collision_type = GameCollisionTypes.Chassis
  shape.friction = chassisFriction
  state.bikeShapes.add(shape)

  return shape

proc addSwingArm(state: GameState, chassisOffset: Vect): Body =
  let space = state.space
  let swingArmMass = 1.5
  let swingArmWidth = swingArmWidth
  let swingArmHeight = swingArmHeight

  let swingArmMoment = momentForBox(swingArmMass, swingArmWidth, swingArmHeight)
  let swingArm = space.addBody(newBody(swingArmMass, swingArmMoment))
  swingArm.position = localToWorld(state.chassis, chassisOffset)
  swingArm.angle = state.chassis.angle

  let swingArmShape = space.addShape(newBoxShape(swingArm, swingArmWidth, swingArmHeight, 0f))
  swingArmShape.filter = SHAPE_FILTER_NONE # no collisions
  swingArmShape.elasticity = 0.0f
  swingArmShape.friction = 0.7f
  state.bikeShapes.add(swingArmShape)
  state.swingArmShape = swingArmShape

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

  let forkArmShape = space.addShape(newBoxShape(forkArm, forkArmWidth, forkArmHeight, 0f))
  forkArmShape.filter = SHAPE_FILTER_NONE # no collisions
  forkArmShape.elasticity = 0.0f
  forkArmShape.friction = 0.7f
  state.bikeShapes.add(forkArmShape)
  state.forkArmShape = forkArmShape

  return forkArm

proc removeBikeConstraints*(state: GameState) =
  let space = state.space

  for constraint in state.bikeConstraints:
    space.removeConstraint(constraint)
  state.bikeConstraints.setLen(0)

# proc removeBikeShapes(state: GameState) =
#   let space = state.space

#   for shape in state.bikeShapes:
#     space.removeShape(shape)
#   state.bikeShapes.setLen(0)

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

  ## SwingArm (arm between chassis and rear wheel)
  
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
      v(-swingArmWidth*2.0*dd, swingArmHeight*0.5), 
      v(swingArmWidth*0.3*dd, swingArmHeight*0.5), 
      vzero
    )
  ))
  # push rearWheel to end of swing arm
  bikeConstraints.add(space.addConstraint(
    swingArm.newDampedSpring(rearWheel, swingArmEndCenter, vzero, swingArmWidth, 40f, 10f)
  ))
  # swing arm rotation
  bikeConstraints.add(space.addConstraint(
    chassis.newDampedRotarySpring(swingArm, 0.15*PI*dd, 30_000.0, 2_000.0)
  ))

  ## fork arm (arm between chassis and front wheel)

  # attach fork arm to chassis
  bikeConstraints.add(space.addConstraint(
    chassis.newPivotJoint(
      forkArm, 
      forkArmPosOffset.transform(dd) + forkArmTopCenterOffset,
      forkArmTopCenterOffset
    )
  ))
  # limit front wheel to fork arm
  bikeConstraints.add(space.addConstraint(
    forkArm.newGrooveJoint(
      frontWheel, 
      vzero,
      v(0f, forkArmHeight), 
      vzero
    )
  ))
  # push front wheel to end of fork arm
  state.forkArmSpring = forkArm.newDampedSpring(
    frontWheel, forkArmTopCenterOffset, vzero, forkArmHeight, 70.0, 10.0
  )
  
  bikeConstraints.add(space.addConstraint(
    state.forkArmSpring
  ))
  # fork arm rotation
  bikeConstraints.add(space.addConstraint(
    chassis.newDampedRotarySpring(forkArm, 0.15f*PI*dd, 20_000f, 3_000f) # todo rest angle?
  ))

  state.bikeConstraints = bikeConstraints

proc flipBikeDirection*(state: GameState) =
  let chassis = state.chassis

  state.removeBikeConstraints()

  swap(state.rearWheel, state.frontWheel)
  state.forkArm.flip(relativeTo = chassis)
  state.swingArm.flip(relativeTo = chassis)  

  state.setBikeConstraints()

proc initGameBike*(state: GameState) =
  let dd = state.driveDirection

  state.chassis = state.addChassis(state.level.initialChassisPosition)
  state.rearWheel = state.addWheel(rearWheelOffset.transform(dd))
  state.frontWheel = state.addWheel(frontWheelOffset.transform(dd))
  state.swingArm = state.addSwingArm(swingArmPosOffset.transform(dd))
  state.forkArm = state.addForkArm(forkArmPosOffset.transform(dd))
  
  state.setBikeConstraints()
  initBikeSound()

proc isBikeInLevelBounds*(state: GameState): bool =
  state.level.chassisBounds.containsVect(
    state.chassis.position
  )

proc updateGameBike*(state: GameState) =
  updateBikeSound(state)

proc pauseGameBike*() =
  pauseBikeSound()

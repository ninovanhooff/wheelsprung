import chipmunk7
import chipmunk/chipmunk_utils
import std/math
import game_types

const
    torsoMass = 1f
    torsoSize = v(7.0, 16.0)
    torsoRotation = degToRad(35f)
    
    # offset from torso, align top of head with top of torso
    headRadius = 6f
    headMass = 0.1f
    headOffset = v(-2.0, -15.0)
    headRotationOffset = degToRad(-35.0)

    # offset from torso, align bottom of tail with bottom of torso
    tailOffset = v(-12.0, 6.0)
    tailMass = 0.1f
    tailSize = v(19, 25)
    tailRotationOffset = -torsoRotation
    
    # offset from torso, align top of arm with top of torso
    upperArmSize = v(4.0, 13.0)
    upperArmMass = 0.25
    upperArmRotationOffset = degToRad(-70.0)
    upperArmOffset = v(5.0, -3.0)

    elbowRotaryLimitAngle = 7/8 * PI # full bend minus 22.5 degrees

    # offset from upper arm
    lowerArmSize = v(3.0, 11.0)
    lowerArmOffset = v(3.0, 8.0)
    lowerArmMass = 0.2f
    lowerArmRotationOffset = degToRad(-55f)

    # offset from torso, align top of leg with bottom of torso
    upperLegSize = v(5.0, 15.0)
    upperLegMass = 0.25f
    upperLegRotationOffset = degToRad(-70f)
    upperLegOffset = v(6.0, torsoSize.y/2 + 2.0)
    # offset from upper leg
    lowerLegSize = v(4f, 11f)
    lowerLegOffset = v(-2.5, 10.0)
    lowerLegMass = 0.2f
    lowerLegRotationOffset = degToRad(35f)

proc resetRiderConstraintForces*(state: GameState) =
  echo("resetRiderConstraintForces")
  state.shoulderPivot.maxForce=900.0
  state.chassisKneePivot.maxForce=0.0
  state.elbowRotaryLimit.maxForce=2_000.0
  state.elbowPivot.maxForce=0.0

proc flip(joint: PivotJoint) =
  joint.anchorA = joint.anchorA.flip()
  joint.anchorB = joint.anchorB.flip()

proc flip(joint: RotaryLimitJoint) =
  let temp = joint.min
  joint.min = -joint.max
  joint.max = -temp

proc offset(joint: PivotJoint, offset: Vect) =
  joint.anchorA = joint.anchorA + offset

proc addRider*(state: GameState, torsoPosition: Vect) =
    let space = state.space
    let dd = state.driveDirection

    let torsoAngle = state.chassis.angle + torsoRotation * dd
    let riderTorso = space.addBox(torsoPosition, torsoSize, torsoMass, torsoAngle)[0]
    state.riderTorso = riderTorso

    let tailPosition = localToWorld(riderTorso, tailOffset.transform(dd))
    let tailAngle = torsoAngle + tailRotationOffset * dd
    state.riderTail = space.addBox(tailPosition, tailSize, tailMass, tailAngle)[0]

    let headPosition = localToWorld(riderTorso, headOffset.transform(dd))
    let headAngle = torsoAngle + headRotationOffset * dd
    state.riderHead = space.addCircle(headPosition, headRadius, headMass, headAngle, 2f, 0f, GameCollisionTypes.Head, GameShapeFilters.Player)[0]
    
    let upperArmPosition = localToWorld(riderTorso, upperArmOffset.transform(dd))
    let upperArmAngle = torsoAngle + upperArmRotationOffset * dd
    state.riderUpperArm = space.addBox(upperArmPosition, upperArmSize, upperArmMass, upperArmAngle)[0]
    
    let lowerArmPosition = localToWorld(state.riderUpperArm, lowerArmOffset.transform(dd))
    let lowerArmAngle = upperArmAngle + lowerArmRotationOffset * dd
    state.riderLowerArm = space.addBox(lowerArmPosition, lowerArmSize, lowerArmMass, lowerArmAngle)[0]

    let upperLegPosition = localToWorld(riderTorso, upperLegOffset.transform(dd))
    let upperLegAngle = torsoAngle + upperLegRotationOffset * dd
    state.riderUpperLeg = space.addBox(upperLegPosition, upperLegSize, upperLegMass, upperLegAngle)[0]

    let lowerLegPosition = localToWorld(state.riderUpperLeg, lowerLegOffset.transform(dd))
    let lowerLegAngle = upperLegAngle + lowerLegRotationOffset * dd
    state.riderLowerLeg = space.addBox(lowerLegPosition, lowerLegSize, lowerLegMass, lowerLegAngle)[0]

    # match velocity of rider to bike
    let velocity: Vect = state.chassis.velocity
    for body in state.getRiderBodies():
      body.velocity = velocity

proc setRiderConstraints(state: GameState) =
  let space = state.space
  let chassis = state.chassis
  let riderTorso = state.riderTorso
  let dd = state.driveDirection

  var riderConstraints : seq[Constraint] = state.riderConstraints

  # pivot torso around ass, and joint ass to bike chassis
  let riderAssLocalPosition = v(0, torsoSize.y/2f)
  let riderAssWorldPosition = localToWorld(riderTorso, riderAssLocalPosition)
  state.assPivot = chassis.newPivotJoint(
      riderTorso,
      riderAssWorldPosition
    )
  riderConstraints.add(space.addConstraint(
    state.assPivot
  ))

  # pivot shoulder to bike chassis
  let riderTorsoShoulderLocalPosition = v(0.0, -torsoSize.y/2)
  let riderTorsoShoulderWorldPosition = localToWorld(riderTorso, riderTorsoShoulderLocalPosition)
  state.shoulderPivot = state.chassis.newPivotJoint(
      riderTorso,
      riderTorsoShoulderWorldPosition
    )
  riderConstraints.add(space.addConstraint(
    state.shoulderPivot
  ))

  # pivot shoulder to torso
  let riderUpperArmShoulderLocalPosition = v(0f, -upperArmSize.y/2f + upperArmSize.x/2f) # + half upper arm width
  let riderShoulderWorldPosition = localToWorld(state.riderUpperArm, riderUpperArmShoulderLocalPosition)
  state.upperArmPivot = riderTorso.newPivotJoint(
      state.riderUpperArm,
      riderShoulderWorldPosition
    )
  riderConstraints.add(space.addConstraint(
    state.upperArmPivot
  ))

  # head pivot
  let riderHeadNeckLocalPosition = vzero # head on a stick, to reduce chaos don't allow head to move relative to torso
  let riderHeadAnchorWorldPosition = localToWorld(state.riderHead, riderHeadNeckLocalPosition)
  state.headPivot = riderTorso.newPivotJoint(
      state.riderHead,
      riderHeadAnchorWorldPosition
    )
  riderConstraints.add(space.addConstraint(
    state.headPivot
  ))

  # head rotation spring
  state.headRotarySpring = state.riderHead.newDampedRotarySpring(riderTorso, headRotationOffset * dd, 1_000.0, 100.0)
  riderConstraints.add(space.addConstraint(
    state.headRotarySpring  
  ))

  # tail pivot
  let riderTailLocalPosition = v(tailSize.x / 2f - 2f, tailSize.y / 2f - 6f)
  let riderTailWorldPosition = localToWorld(state.riderTail, riderTailLocalPosition)
  state.tailPivot = chassis.newPivotJoint(
      state.riderTail,
      riderTailWorldPosition
    )
  riderConstraints.add(space.addConstraint(
    state.tailPivot
  ))

  # tail rotary spring
  state.tailRotarySpring = state.riderTail.newDampedRotarySpring(riderTorso, tailRotationOffset * dd, 500.0, 200.0)
  riderConstraints.add(space.addConstraint(
    state.tailRotarySpring
  ))

  # Elbow pivot
  let riderLowerArmElbowLocalPosition = v(0f, -lowerArmSize.y/2f + lowerArmSize.x/2f)
  let riderElbowWorldPosition = localToWorld(state.riderLowerArm, riderLowerArmElbowLocalPosition)
  riderConstraints.add(space.addConstraint(
    state.riderUpperArm.newPivotJoint(
      state.riderLowerArm,
      riderElbowWorldPosition
    )
  ))

  # Elbow rotary limit
  state.elbowRotaryLimit = state.riderLowerArm.newRotaryLimitJoint(
    state.riderUpperArm,
    0.1,
    elbowRotaryLimitAngle,
  )
  if dd == DD_LEFT:
    state.elbowRotaryLimit.flip()
  riderConstraints.add(space.addConstraint(
    state.elbowRotaryLimit
  ))

  # Pivot Elbow to chassis
  state.elbowPivot = chassis.newPivotJoint(
      state.riderLowerArm,
      riderElbowWorldPosition
    )
  state.elbowPivot.maxForce = 0.0 # only for direction change
  riderConstraints.add(space.addConstraint(state.elbowPivot))

  # Pivot hand to handlebars
  let riderLowerArmHandLocalPosition = v(0.0, lowerArmSize.y/2)
  let riderHandWorldPosition = localToWorld(state.riderLowerArm, riderLowerArmHandLocalPosition)
  state.handPivot = chassis.newPivotJoint(
      state.riderLowerArm,
      riderHandWorldPosition
    )
  # Should be slightly stronger than elbow pivot to be able to put hands behind head
  # during attitude adjustment. Not too much, because we don't want it to overextend the elbow
  # state.handPivot.maxForce = 200.0
  riderConstraints.add(space.addConstraint(state.handPivot))

  # Pivot upper leg
  let riderUpperLegHipLocalPosition = v(0f, -upperLegSize.y/2f + upperLegSize.x/2f)
  let riderHipWorldPosition = localToWorld(state.riderUpperLeg, riderUpperLegHipLocalPosition)
  state.hipPivot = chassis.newPivotJoint(
      state.riderUpperLeg,
      riderHipWorldPosition
    )
  riderConstraints.add(space.addConstraint(
    state.hipPivot
  ))

  # Pivot lower leg to upper leg
  let riderLowerLegKneeLocalPosition = v(0f, -lowerLegSize.y/2f + lowerLegSize.x/2f)
  let riderKneeWorldPosition = localToWorld(state.riderLowerLeg, riderLowerLegKneeLocalPosition)
  riderConstraints.add(space.addConstraint(
    state.riderUpperLeg.newPivotJoint(
      state.riderLowerLeg,
      riderKneeWorldPosition
    )
  ))

  state.chassisKneePivot = chassis.newPivotJoint(
      state.riderLowerLeg,
      riderKneeWorldPosition
    )
  # Pivot knee to chassis
  riderConstraints.add(space.addConstraint(
    state.chassisKneePivot
  ))

  # Pivot foot to pedal
  let riderLowerLegFootLocalPosition = v(0.0, lowerLegSize.y/2)
  let riderFootWorldPosition = localToWorld(state.riderLowerLeg, riderLowerLegFootLocalPosition)
  state.footPivot = chassis.newPivotJoint(
      state.riderLowerLeg,
      riderFootWorldPosition
    )
  riderConstraints.add(space.addConstraint(
    state.footPivot
  ))

  state.riderConstraints = riderConstraints
  state.resetRiderConstraintForces()

proc initGameRider*(state: GameState, riderPosition: Vect) =
  state.addRider(riderPosition)
  state.setRiderConstraints()

proc setAttitudeAdjustForward(state: GameState, dirV: Vect) =
  state.assPivot.offset(v(1.0 , -1.0).transform(dirV))
  state.hipPivot.offset(v(1.0, -1.0).transform(dirV))
  state.shoulderPivot.offset(v(3.0, 2.0).transform(dirV))
  # state.handPivot.offset(v(-13.0, -20.0).transform(dirV))

proc setAttitudeAdjustBackward(state: GameState, dirV: Vect) =
  state.assPivot.offset(v(-1.0 , 2.0).transform(dirV))
  state.hipPivot.offset(v(-1.0, 2.0).transform(dirV))
  state.shoulderPivot.offset(v(-2.0, -2.0).transform(dirV))
#  state.handPivot.offset(v(-19.0, -22.0).transform(dirV))
  # state.handPivot.offset(v(-23.0, 5.0).transform(dirV))

proc resetRiderAttitudePosition*(state: GameState) =
  if state.riderAttitudePosition == RiderAttitudePosition.Neutral:
    return

  let dirV = v(
    state.driveDirection * -1.0,
    -1.0
  )

  if state.riderAttitudePosition == RiderAttitudePosition.Forward:
    setAttitudeAdjustForward(state, dirV)
  else:
    setAttitudeAdjustBackward(state, dirV)

  state.riderAttitudePosition = RiderAttitudePosition.Neutral

proc setRiderAttitudeAdjustPosition*(state: GameState, direction: float) =
  if direction > 0.0 and state.riderAttitudePosition == RiderAttitudePosition.Forward:
    return
  elif direction < 0.0 and state.riderAttitudePosition == RiderAttitudePosition.Backward:
    return
  elif direction != 0.0 and state.riderAttitudePosition != RiderAttitudePosition.Neutral:
    resetRiderAttitudePosition(state)
    return


  let dirV = v(
    state.driveDirection,
    1.0
  )
  if direction > 0.0:
    setAttitudeAdjustForward(state, dirV)
    state.riderAttitudePosition = RiderAttitudePosition.Forward
  else:
    setAttitudeAdjustBackward(state, dirV)
    state.riderAttitudePosition = RiderAttitudePosition.Backward


proc flipRiderDirection*(state: GameState, riderPosition: Vect) =
  state.assPivot.flip()
  state.shoulderPivot.flip()
  state.shoulderPivot.maxForce=100.0 # allow shoulder to move
  state.upperArmPivot.flip()
  state.hipPivot.flip()
  state.footPivot.flip()
  state.chassisKneePivot.flip()
  state.elbowPivot.flip()
  state.elbowRotaryLimit.flip()
  state.chassisKneePivot.maxForce=2_000.0
  state.elbowPivot.maxForce=1_000.0
  state.elbowRotaryLimit.maxForce=0.0 # Allow elbow to over-extend
  state.handPivot.flip()
  state.headPivot.flip()
  state.headRotarySpring.restAngle = -state.headRotarySpring.restAngle
  state.tailPivot.flip()
  state.tailRotarySpring.restAngle = -state.tailRotarySpring.restAngle

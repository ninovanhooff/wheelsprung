import chipmunk7
import utils
import chipmunk_utils
import std/math
import game_types

const 
    torsoMass = 1f
    torsoSize = v(7.0, 16.0)
    torsoRotation = degToRad(35f)
    
     # offset from torso, align top of head with top of torso
    headRadius = 6f
    headMass = 0.1f
    headOffset = v(-3.0, -12.0)
    headRotationOffset = degToRad(-35.0)
    
    # offset from torso, align top of arm with top of torso
    upperArmSize = v(4.0, 14.0)
    upperArmMass = 0.25
    upperArmRotationOffset = degToRad(-70.0)
    upperArmOffset = v(7.0, -3.0)

    # offset from upper arm
    lowerArmSize = v(3.0, 10.0)
    lowerArmOffset = v(2.0, 9.0)
    lowerArmMass = 0.2f
    lowerArmRotationOffset = degToRad(-60f)

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

proc addRider*(state: GameState, torsoPosition: Vect) =
    let space = state.space
    let dd = state.driveDirection

    let torsoAngle = state.chassis.angle + torsoRotation * dd
    let riderTorso = space.addBox(torsoPosition, torsoSize, torsoMass, torsoAngle, state.riderShapes)
    state.riderTorso = riderTorso

    let headPosition = localToWorld(riderTorso, headOffset.transform(dd))
    let headAngle = torsoAngle + headRotationOffset * dd
    state.riderHead = space.addCircle(headPosition, headRadius, headMass, headAngle)
    
    let upperArmPosition = localToWorld(riderTorso, upperArmOffset.transform(dd))
    let upperArmAngle = torsoAngle + upperArmRotationOffset * dd
    state.riderUpperArm = space.addBox(upperArmPosition, upperArmSize, upperArmMass, upperArmAngle, state.riderShapes)
    
    let lowerArmPosition = localToWorld(state.riderUpperArm, lowerArmOffset.transform(dd))
    let lowerArmAngle = upperArmAngle + lowerArmRotationOffset * dd
    state.riderLowerArm = space.addBox(lowerArmPosition, lowerArmSize, lowerArmMass, lowerArmAngle, state.riderShapes)

    let upperLegPosition = localToWorld(riderTorso, upperLegOffset.transform(dd))
    let upperLegAngle = torsoAngle + upperLegRotationOffset * dd
    state.riderUpperLeg = space.addBox(upperLegPosition, upperLegSize, upperLegMass, upperLegAngle, state.riderShapes)

    let lowerLegPosition = localToWorld(state.riderUpperLeg, lowerLegOffset.transform(dd))
    let lowerLegAngle = upperLegAngle + lowerLegRotationOffset * dd
    state.riderLowerLeg = space.addBox(lowerLegPosition, lowerLegSize, lowerLegMass, lowerLegAngle, state.riderShapes)

    # match velocity of rider to bike
    let velocity: Vect = state.chassis.velocity
    for body in state.getRiderBodies():
      body.velocity = velocity

proc setRiderConstraints(state: GameState) =
  let space = state.space
  let riderTorso = state.riderTorso
  let dd = state.driveDirection

  var riderConstraints : seq[Constraint] = state.riderConstraints

  # pivot torso around ass, and joint ass to bike chassis
  let riderAssLocalPosition = v(0, torsoSize.y/2f)
  let riderAssWorldPosition = localToWorld(riderTorso, riderAssLocalPosition)
  state.assPivot = state.chassis.newPivotJoint(
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
  state.shoulderPivot.maxForce = 900.0 # allow shoulders to sag towards bike on impact


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

  # Elbow pivot
  let riderLowerArmElbowLocalPosition = v(0f, -lowerArmSize.y/2f + lowerArmSize.x/2f)
  let riderElbowWorldPosition = localToWorld(state.riderLowerArm, riderLowerArmElbowLocalPosition)
  riderConstraints.add(space.addConstraint(
    state.riderUpperArm.newPivotJoint(
      state.riderLowerArm,
      riderElbowWorldPosition
    )
  ))

  # Pivot Elbow to chassis
  state.elbowPivot = state.chassis.newPivotJoint(
      state.riderLowerArm,
      riderElbowWorldPosition
    )
  state.elbowPivot.maxForce = 0.0 # only for direction change
  riderConstraints.add(space.addConstraint(state.elbowPivot))

  # Pivot hand to handlebars
  let riderLowerArmHandLocalPosition = v(0.0, lowerArmSize.y/2)
  let riderHandWorldPosition = localToWorld(state.riderLowerArm, riderLowerArmHandLocalPosition)
  state.handPivot = state.chassis.newPivotJoint(
      state.riderLowerArm,
      riderHandWorldPosition
    )
  riderConstraints.add(space.addConstraint(state.handPivot))

  # Pivot upper leg
  let riderUpperLegHipLocalPosition = v(0f, -upperLegSize.y/2f + upperLegSize.x/2f)
  let riderHipWorldPosition = localToWorld(state.riderUpperLeg, riderUpperLegHipLocalPosition)
  state.hipPivot = state.chassis.newPivotJoint(
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

  state.chassisKneePivot = state.chassis.newPivotJoint(
      state.riderLowerLeg,
      riderKneeWorldPosition
    )
  # Pivot knee to chassis
  riderConstraints.add(space.addConstraint(
    state.chassisKneePivot
  ))
  state.chassisKneePivot.maxForce = 0.0 # only for direction change

  # Pivot foot to pedal
  let riderLowerLegFootLocalPosition = v(0.0, lowerLegSize.y/2)
  let riderFootWorldPosition = localToWorld(state.riderLowerLeg, riderLowerLegFootLocalPosition)
  state.footPivot = state.chassis.newPivotJoint(
      state.riderLowerLeg,
      riderFootWorldPosition
    )
  riderConstraints.add(space.addConstraint(
    state.footPivot
  ))

  state.riderConstraints = riderConstraints

proc initGameRider*(state: GameState, riderPosition: Vect) =
  state.addRider(riderPosition)
  state.setRiderConstraints()

proc flip(joint: PivotJoint) =
  joint.anchorA = joint.anchorA.flip()

proc flipRiderDirection*(state: GameState, riderPosition: Vect) =
  state.assPivot.flip()
  state.shoulderPivot.flip()
  state.shoulderPivot.maxForce=100.0
  state.upperArmPivot.flip()
  state.hipPivot.flip()
  state.footPivot.flip()
  state.chassisKneePivot.flip()
  state.elbowPivot.flip()
  state.chassisKneePivot.maxForce=2_000.0
  state.elbowPivot.maxForce=1_000.0
  state.handPivot.flip()
  state.headPivot.flip()

  state.headRotarySpring.restAngle = -state.headRotarySpring.restAngle
  # state.riderHead.angle=0.0

  # state.headRotarySpring.restAngle = -state.headRotarySpring.restAngle

proc resetRiderConstraintForces*(state: GameState) =
  print("resetRiderConstraintForces")
  state.shoulderPivot.maxForce=900.0
  state.chassisKneePivot.maxForce=0.0
  state.elbowPivot.maxForce=0.0
  # state.headRotarySpring = state.riderHead.newDampedRotarySpring(state.riderTorso, headRotationOffset * state.driveDirection, 10000.0, 900.0)
  # discard state.space.addConstraint(
  #   state.headRotarySpring  
  # )


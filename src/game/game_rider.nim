import chipmunk7
import chipmunk_utils
import std/math
import game_types

const 
    torsoMass = 1f
    torsoSize = v(7.0, 18.0)
    torsoRotation = degToRad(35f)
    
     # offset from torso, align top of head with top of torso
    headRadius = 6f
    headMass = 0.1f
    headOffset = v(-2.0, -14.0)
    headAngle = degToRad(-35.0)
    
    # offset from torso, align top of arm with top of torso
    upperArmSize = v(4f, 14f)
    upperArmMass = 0.25f
    upperArmRotationOffset = degToRad(-70f)
    upperArmOffset = v(6f, -4f)

    # offset from upper arm
    lowerArmSize = v(3.0, 10.0)
    lowerArmOffset = v(2.0, 10f)
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
    let riderTorso = space.addBox(torsoPosition, torsoSize, torsoMass, torsoAngle)
    state.riderTorso = riderTorso

    let headPosition = localToWorld(riderTorso, headOffset.transform(dd))
    state.riderHead = space.addCircle(headPosition, headRadius, headMass, torsoAngle + headAngle)
    
    let upperArmPosition = localToWorld(riderTorso, upperArmOffset.transform(dd))
    let upperArmAngle = torsoAngle + upperArmRotationOffset * dd
    state.riderUpperArm = space.addBox(upperArmPosition, upperArmSize, upperArmMass, upperArmAngle)
    
    let lowerArmPosition = localToWorld(state.riderUpperArm, lowerArmOffset.transform(dd))
    let lowerArmAngle = upperArmAngle + lowerArmRotationOffset * dd
    state.riderLowerArm = space.addBox(lowerArmPosition, lowerArmSize, lowerArmMass, lowerArmAngle)

    let upperLegPosition = localToWorld(riderTorso, upperLegOffset.transform(dd))
    let upperLegAngle = torsoAngle + upperLegRotationOffset * dd
    state.riderUpperLeg = space.addBox(upperLegPosition, upperLegSize, upperLegMass, upperLegAngle)

    let lowerLegPosition = localToWorld(state.riderUpperLeg, lowerLegOffset.transform(dd))
    let lowerLegAngle = upperLegAngle + lowerLegRotationOffset * dd
    state.riderLowerLeg = space.addBox(lowerLegPosition, lowerLegSize, lowerLegMass, lowerLegAngle)

    # match velocity of rider to bike
    let velocity: Vect = state.chassis.velocity
    for body in state.getRiderBodies():
      body.velocity = velocity

proc setRiderConstraints(state: GameState) =
  let space = state.space
  let riderTorso = state.riderTorso

  var riderConstraints : seq[Constraint] = state.riderConstraints

  # pivot torso around ass, and joint ass to bike chassis
  let riderAssLocalPosition = v(0, torsoSize.y/2f)
  let riderAssWorldPosition = localToWorld(riderTorso, riderAssLocalPosition)
  riderConstraints.add(space.addConstraint(
    state.chassis.newPivotJoint(
      riderTorso,
      riderAssWorldPosition
    )
  ))

  # pivot should to bike chassis
  let riderTorsoShoulderLocalPosition = v(0.0, -torsoSize.y/2)
  let riderTorsoShoulderWorldPosition = localToWorld(riderTorso, riderTorsoShoulderLocalPosition)
  riderConstraints.add(space.addConstraint(
    state.chassis.newPivotJoint(
      riderTorso,
      riderTorsoShoulderWorldPosition
    )
  ))
  riderConstraints[^1].maxForce = 900.0 # allow shoulders to sag towards bike on impact


  # shoulder pivot
  let riderUpperArmShoulderLocalPosition = v(0f, -upperArmSize.y/2f + upperArmSize.x/2f) # + half upper arm width
  let riderShoulderWorldPosition = localToWorld(state.riderUpperArm, riderUpperArmShoulderLocalPosition)
  riderConstraints.add(space.addConstraint(
    riderTorso.newPivotJoint(
      state.riderUpperArm,
      riderShoulderWorldPosition
    )
  ))

  # head pivot
  let riderHeadNeckLocalPosition = v(0f, 0f) # head on a stick, to reduce chaos don't allow head to move relative to torso
  let riderHeadAnchorWorldPosition = localToWorld(state.riderHead, riderHeadNeckLocalPosition)
  riderConstraints.add(space.addConstraint(
    riderTorso.newPivotJoint( # head on a stick, to reduce chaos don't allow head to move relative to torso
      state.riderHead,
      riderHeadAnchorWorldPosition
    )
  ))
  # head rotation spring
  riderConstraints.add(space.addConstraint(
    state.riderHead.newDampedRotarySpring(riderTorso, state.riderHead.angle, 1000f, 9000f) # todo rest angle?
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

  # Pivot hand to handlebars
  let riderLowerArmHandLocalPosition = v(0.0, lowerArmSize.y/2)
  let riderHandWorldPosition = localToWorld(state.riderLowerArm, riderLowerArmHandLocalPosition)
  riderConstraints.add(space.addConstraint(
    state.chassis.newPivotJoint(
      state.riderLowerArm,
      riderHandWorldPosition
    )
  ))

  # Pivot upper leg
  let riderUpperLegHipLocalPosition = v(0f, -upperLegSize.y/2f + upperLegSize.x/2f)
  let riderHipWorldPosition = localToWorld(state.riderUpperLeg, riderUpperLegHipLocalPosition)
  riderConstraints.add(space.addConstraint(
    state.chassis.newPivotJoint(
      state.riderUpperLeg,
      riderHipWorldPosition
    )
  ))

  # Pivot lower leg
  let riderLowerLegKneeLocalPosition = v(0f, -lowerLegSize.y/2f + lowerLegSize.x/2f)
  let riderKneeWorldPosition = localToWorld(state.riderLowerLeg, riderLowerLegKneeLocalPosition)
  riderConstraints.add(space.addConstraint(
    state.riderUpperLeg.newPivotJoint(
      state.riderLowerLeg,
      riderKneeWorldPosition
    )
  ))

  # Pivot foot to pedal
  let riderLowerLegFootLocalPosition = v(0.0, lowerLegSize.y/2)
  let riderFootWorldPosition = localToWorld(state.riderLowerLeg, riderLowerLegFootLocalPosition)
  riderConstraints.add(space.addConstraint(
    state.chassis.newPivotJoint(
      state.riderLowerLeg,
      riderFootWorldPosition
    )
  ))

  state.riderConstraints = riderConstraints


proc removeRider(state: GameState) =
  let space = state.space
  for constraint in state.riderConstraints:
    space.removeConstraint(constraint)
  state.riderConstraints = @[]

  for body in state.getRiderBodies():
    space.removeBody(body)

proc initRiderPhysics*(state: GameState, riderPosition: Vect) =
  state.addRider(riderPosition)
  state.setRiderConstraints()

proc flipRiderDirection*(state: GameState, riderPosition: Vect) =
  state.removeRider()
  state.initRiderPhysics(riderPosition)


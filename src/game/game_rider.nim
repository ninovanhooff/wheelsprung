import chipmunk7
import chipmunk_utils
import std/math
import game_types

const 
    torsoMass = 1f
    torsoSize = v(10f, 20f)
    torsoRotation = degToRad(45f)
    
     # offset from torso, align top of head with top of torso
    headRadius = 6f
    headMass = 0.1f
    headOffset = v(0f, -20f)
    
    # offset from torso, align top of arm with top of torso
    upperArmSize = v(5f, 12f)
    upperArmMass = 0.25f
    upperArmRotationOffset = degToRad(-70f)
    upperArmOffset = v(5f, -3f)

    # offset from upper arm
    lowerArmSize = v(3f, 11f)
    lowerArmOffset = v(3f, 9f)
    lowerArmMass = 0.2f
    lowerArmRotationOffset = degToRad(-75f)

    # offset from lower arm
    handRadius = 2f
    handMass = 0.1f
    handOffset = v(-1f, 7f)

proc addRider*(state: GameState, torsoPosition: Vect) =
    let space = state.space
    let dd = state.driveDirection

    let torsoAngle = torsoRotation * dd
    let riderTorso = space.addBox(torsoPosition, torsoSize, torsoMass, torsoAngle)
    state.riderTorso = riderTorso
    
    let headPosition = localToWorld(riderTorso, headOffset.transform(dd))
    state.riderHead = space.addCircle(headPosition, headRadius, headMass, torsoAngle) # head angle matches torso angle
    
    let upperArmPosition = localToWorld(riderTorso, upperArmOffset.transform(dd))
    let upperArmAngle = torsoAngle + upperArmRotationOffset * dd
    state.riderUpperArm = space.addBox(upperArmPosition, upperArmSize, upperArmMass, upperArmAngle)
    
    let lowerArmPosition = localToWorld(state.riderUpperArm, lowerArmOffset.transform(dd))
    let lowerArmAngle = upperArmAngle + lowerArmRotationOffset * dd
    state.riderLowerArm = space.addBox(lowerArmPosition, lowerArmSize, lowerArmMass, lowerArmAngle)

    let handPosition = localToWorld(state.riderLowerArm, handOffset.transform(dd))
    state.riderHand = space.addCircle(handPosition, handRadius, handMass)

proc setRiderConstraints(state: GameState) =
  let space = state.space
  let riderTorso = state.riderTorso

  var riderConstraints : seq[Constraint] = state.riderConstraints

  let riderAssLocalPosition = v(0, torsoSize.y/2f)
  let riderAssWorldPosition = localToWorld(riderTorso, riderAssLocalPosition)
  riderConstraints.add(space.addConstraint(
    # pivot torso around ass, and joint ass to bike chassis
    state.chassis.newPivotJoint(
      riderTorso,
      worldToLocal(state.chassis, riderAssWorldPosition),
      riderAssLocalPosition
    )
  ))

  let riderUpperArmShoulderLocalPosition = v(0f, -upperArmSize.y/2f + upperArmSize.x/2f) # + half upper arm width
  let riderShoulderWorldPosition = localToWorld(state.riderUpperArm, riderUpperArmShoulderLocalPosition)
  riderConstraints.add(space.addConstraint(
    # pivot torso around ass, and joint ass to bike chassis
    riderTorso.newPivotJoint(
      state.riderUpperArm,
      worldToLocal(riderTorso, riderShoulderWorldPosition),
      riderUpperArmShoulderLocalPosition
    )
  ))
  riderConstraints.add(space.addConstraint(
    riderTorso.newDampedRotarySpring(state.chassis, riderTorso.angle, 10_000f, 7_000f) # todo rest angle?
  ))

  let riderHeadNeckLocalPosition = v(0f, 0f) # head on a stick, to reduce chaos don't allow head to move relative to torso
  let riderHeadAnchorWorldPosition = localToWorld(state.riderHead, riderHeadNeckLocalPosition)
  riderConstraints.add(space.addConstraint(
    riderTorso.newPinJoint( # head on a stick, to reduce chaos don't allow head to move relative to torso
      state.riderHead,
      worldToLocal(riderTorso, riderHeadAnchorWorldPosition),
      riderHeadNeckLocalPosition
    )
  ))
  riderConstraints.add(space.addConstraint(
    state.riderHead.newDampedRotarySpring(riderTorso, state.riderHead.angle, 1000f, 9000f) # todo rest angle?
  ))

  let riderLowerArmElbowLocalPosition = v(0f, -lowerArmSize.y/2f + lowerArmSize.x/2f)
  let riderElbowWorldPosition = localToWorld(state.riderLowerArm, riderLowerArmElbowLocalPosition)
  riderConstraints.add(space.addConstraint(
    state.riderUpperArm.newPivotJoint(
      state.riderLowerArm,
      worldToLocal(state.riderUpperArm, riderElbowWorldPosition),
      riderLowerArmElbowLocalPosition
    )
  ))

  let riderHandWristLocalPosition = v(0f, 0f)
  let riderHandWorldPosition = localToWorld(state.riderHand, riderHandWristLocalPosition)
  riderConstraints.add(space.addConstraint(
    state.riderLowerArm.newPinJoint(
      state.riderHand,
      worldToLocal(state.riderLowerArm, riderHandWorldPosition),
      riderHandWristLocalPosition
    )
  ))

  # pin hand to handlebar
  riderConstraints.add(space.addConstraint(
    state.chassis.newPinJoint( # 
      state.riderHand,
      worldToLocal(state.chassis, localToWorld(state.riderHand, vzero)),
      riderHeadNeckLocalPosition
    )
  ))

  state.riderConstraints = riderConstraints







proc initRiderPhysics*(state: GameState, riderPosition: Vect) =
  state.addRider(riderPosition)
  state.setRiderConstraints()
    
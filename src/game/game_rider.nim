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
    upperArmSize = v(5f, 14f)
    upperArmMass = 0.25f
    upperArmRotationOffset = degToRad(-65f)
    upperArmOffset = v(5f, -3f)

    # offset from upper arm
    lowerArmSize = v(3f, 10f)
    lowerArmOffset = v(3f, 9f)
    lowerArmMass = 0.2f
    lowerArmRotationOffset = degToRad(-70f)

proc addRider*(state: Gamestate, torsoPosition: Vect) =
    let space = state.space
    let dd = state.driveDirection

    let torsoAngle = torsoRotation * dd
    state.riderTorso = space.addBox(torsoPosition, torsoSize, torsoMass, torsoAngle)
    
    let headPosition = localToWorld(state.ridertorso, headOffset * dd)
    state.riderHead = space.addCircle(headPosition, headRadius, headMass)
    
    let upperArmPosition = localToWorld(state.riderTorso, upperArmOffset * dd)
    let upperArmAngle = torsoAngle + upperArmRotationOffset * dd
    state.riderUpperArm = space.addBox(upperArmPosition, upperArmSize, upperArmMass, upperArmAngle)
    
    let lowerArmPosition = localToWorld(state.riderUpperArm, lowerArmOffset * dd)
    let lowerArmAngle = upperArmAngle + lowerArmRotationOffset * dd
    state.riderLowerArm = space.addBox(lowerArmPosition, lowerArmSize, lowerArmMass, lowerArmAngle)

proc initRiderPhysics*(state: GameState, riderPosition: Vect) =
  state.addRider(riderPosition)
    
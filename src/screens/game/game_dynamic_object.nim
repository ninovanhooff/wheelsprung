{.push raises: [].}

import playdate/api
import std/tables
import std/sets
import std/math
import std/options
import chipmunk7
import chipmunk_utils
import common/utils
import common/audio_utils
import common/graphics_utils
import common/fading_sample_player
import game_types
import cache/sound_cache

const
  minImpactVolume: Float = 0.1f
  minRollSoundAngularVelocity: Float = 0.6f # if angular velocity is less than this, don't play roll sound

var 
  rollPlayers = initTable[DynamicObjectType, Option[FadingSamplePlayer]]()
  impactPlayers = initTable[DynamicObjectType, Option[SamplePlayer]]()

proc rollSampleId(objectType: DynamicObjectType): Option[SampleId] =
  case objectType
  of DynamicObjectType.BowlingBall: some(SampleId.BowlingBallRolling)
  of DynamicObjectType.Marble: some(SampleId.MarbleRolling)
  else: none(SampleId)

proc impactSampleId(objectType: DynamicObjectType): Option[SampleId] =
  case objectType
  of DynamicObjectType.BowlingBall: some(SampleId.BowlingBallImpact)
  of DynamicObjectType.Marble: some(SampleId.MarbleImpact)
  else: none(SampleId)

proc getOrLoadFadingSamplePlayer(sampleId: SampleId): FadingSamplePlayer =
  let player = getOrLoadSamplePlayer(sampleId)
  return newFadingSamplePlayer(player, lerpSpeed= 0.15f)

proc getRollPlayer*(objectType: DynamicObjectType): Option[FadingSamplePlayer] =
  rollPlayers.withValue(objectType, value):
    return value[]
  do:
    let player = rollSampleId(objectType).map(getOrLoadFadingSamplePlayer)
    rollPlayers[objectType] = player
    return player

proc getImpactPlayer*(objectType: DynamicObjectType): Option[SamplePlayer] =
  impactPlayers.withValue(objectType, value):
    return value[]
  do:
    let player = impactSampleId(objectType).map(getOrLoadSamplePlayer)
    impactPlayers[objectType] = player
    return player

proc addDynamicObjects*(state: GameState) =
  
  let space = state.space
  for obj in state.level.dynamicBoxes:
    state.dynamicObjects.add(
      newDynamicObject(
        shape = space.addBox(
          obj.position, obj.size, 
          mass = obj.mass,
          angle = obj.angle,
          friction = obj.friction,
          elasticity = obj.elasticity,
          collisionType=GameCollisionTypes.DynamicObject,
          shapeFilter = GameShapeFilters.DynamicObject
        )[1], # get shape from tuple
        objectType = obj.objectType,
      )
    )

  for obj in state.level.dynamicCircles:
    state.dynamicObjects.add(
      newDynamicObject(
        shape = space.addCircle(
          obj.position, obj.radius, 
          mass = obj.mass,
          friction = obj.friction,
          elasticity = obj.elasticity,
          collisionType=GameCollisionTypes.DynamicObject,
          shapeFilter = GameShapeFilters.DynamicObject,
          userData = cast[DataPointer](obj.objectType)
        )[1], # get shape from tuple
        objectType = obj.objectType,
      )
    )

proc updateRollSound(objectType: DynamicObjectType, state: GameState) =
  var fastestAngularVelocity = 0f

  let optRollPlayer = getRollPlayer(objectType)
  if optRollPlayer.isNone:
    return
  let rollPlayer = optRollPlayer.get


  for item in state.dynamicObjects:
    if item.objectType != some(objectType):
      continue
    let shape = item.shape
    var count = 0
    let incrementCount = proc(_: Arbiter) =
      count += 1

    shape.body.eachArbiter(incrementCount)
    if count == 0:
      continue

    # print "considering shape: ", shape.repr
    let angularVelocity = abs(shape.body.angularVelocity)
    if angularVelocity > fastestAngularVelocity:
      fastestAngularVelocity = angularVelocity
  
  let shouldPlay = fastestAngularVelocity > minRollSoundAngularVelocity
  if shouldPlay: 
    if not rollPlayer.isPlaying:
      rollPlayer.fadeIn()
    let targetRate = clamp(fastestAngularVelocity, 0.8f, 1.3f)
    let newRate = lerp(rollPlayer.rate, targetRate, 0.1f)
    rollPlayer.rate = newRate
  elif not shouldPlay and rollPlayer.isPlaying:
    rollPlayer.fadeOut()

  print "updateRollSound: ", objectType, shouldPlay, fastestAngularVelocity
  rollPlayer.update()

let postStepCallback: PostStepFunc = proc(space: Space, dynamicObjectShape: pointer, unused: pointer) {.cdecl raises: [].} =
  let state = cast[GameState](space.userData)
  for objType in DynamicObjectType:
    updateRollSound(objType, state)

let collisionBeginFunc*: CollisionBeginFunc = proc(arb: Arbiter; space: Space; unused: pointer): bool {.cdecl.} =
  var state: GameState = cast[GameState](space.userData)
  var 
    shapeA: Shape
    shapeB: Shape
  arb.shapes(addr(shapeA), addr(shapeB))

  let objectType = cast[DynamicObjectType](shapeA.userData)

  # print "collisionBeginFunc: ", objectType, shapeB.collisionType.repr
  discard space.addPostStepCallback(
    postStepCallback,
    shapeA,
    postStepCallback # key for the post step callback, only called once per step, even if multiple collisions
  )
  return true # also run default collision handler

let collisionPostSolveFunc*: CollisionPostSolveFunc = proc(arb: Arbiter; space: Space; unused: pointer) {.cdecl.} =
  var 
    shapeA: Shape
    shapeB: Shape
  arb.shapes(addr(shapeA), addr(shapeB))

  let totalImpulse = arb.totalImpulse.vlength
  let objectType = cast[DynamicObjectType](shapeA.userData)
  let mass = shapeA.body.mass
  let targetVolume = totalImpulse / mass / 100f
  if arb.isFirstContact and shapeB.collisionType == GameCollisionTypes.Terrain and  targetVolume >= minImpactVolume:
    let impactPlayer = getImpactPlayer(objectType)
    if impactPlayer.isSome:
      let player = impactPlayer.get
      if not player.isPlaying:
        print "impact", totalImpulse, mass
        impactPlayer.get.volume = clamp(targetVolume, 0.0, 1.0)
        impactPlayer.get.playVariation()

  discard space.addPostStepCallback(
    postStepCallback,
    shapeA,
    postStepCallback # key for the post step callback, only called once per step, even if multiple collisions
  )


let collisionSeparateFunc*: CollisionSeparateFunc = proc(arb: Arbiter; space: Space; unused: pointer) {.cdecl.} =
  var state = cast[GameState](space.userData)
  var 
    shapeA: Shape
    shapeB: Shape
  arb.shapes(addr(shapeA), addr(shapeB))

  let objectType = cast[DynamicObjectType](shapeA.userData)

  # print "collisionSeparateFunc: ", objectType, shapeB.collisionType.repr

  discard space.addPostStepCallback(
    postStepCallback,
    shapeA,
    postStepCallback # key for the post step callback, only called once per step, even if multiple collisions
  )
  discard


proc addDynamicObjectHandlers*(space: Space) =
  let handler = space.addWildcardHandler(GameCollisionTypes.DynamicObject)
  handler.beginFunc = collisionBeginFunc
  handler.separateFunc = collisionSeparateFunc
  handler.postSolveFunc = collisionPostSolveFunc


proc drawCircle*(camera: Camera, pos: Vect, radius: float, angle: float, color: LCDColor) =
  # covert from center position to top left
  let drawPos = pos - camera
  let x = (drawPos.x - radius).toInt
  let y = (drawPos.y - radius).toInt
  let size: int = (radius * 2f).toInt
  # angle is in radians, convert to degrees
  let deg = radTodeg(angle)
  gfx.drawEllipse(x,y,size, size, 1, deg+10, deg + 350, color);

proc drawPolyShape(poly: PolyShape, camera: Camera) =
  let numVerts = poly.count
  for i in 0 ..< numVerts:
    let a = localToWorld(poly.body, poly.vert(i)) - camera
    let b = localToWorld(poly.body, poly.vert((i+1) mod numVerts)) - camera
    gfx.drawLine(a.x.toInt, a.y.toInt, b.x.toInt, b.y.toInt, 1, kColorBlack);

proc drawDynamicObjects*(state: GameState) =
  let camera = state.camera
  for obj in state.dynamicObjects:
    let shape = obj.shape
    if shape.kind == cpPolyShape:
      let polyShape = cast[PolyShape](shape)
      if obj.bitmapTable.isSome:
        let body = polyShape.body
        obj.bitmapTable.get.drawRotated(
          body.position - camera,
          body.angle,
        )
      else:
        drawPolyShape(polyShape, camera)
    elif shape.kind == cpCircleShape:
      let circle = cast[CircleShape](shape)
      if obj.bitmapTable.isSome:
        let body = circle.body
        obj.bitmapTable.get.drawRotated(
          body.position - camera + circle.offset,
          body.angle,
        )
      else:
        drawCircle(camera, circle.body.position + circle.offset, circle.radius, circle.body.angle, kColorBlack)
    else:
      print "drawDynamicObjects: Unknown shape kind: ", shape.kind

proc pauseDynamicObjects*() =
  for optPlayer in rollPlayers.values:
    if optPlayer.isSome:
      optPlayer.get.stop()

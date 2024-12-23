import playdate/api
import std/tables
import std/math
import std/options
import chipmunk7
import chipmunk_utils
import common/utils
import common/graphics_utils
import game_types
import cache/sound_cache

var bowlingBallRollPlayer: SamplePlayer

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
          collisionType=GameCollisionTypes.DynamicObject,
          shapeFilter = GameShapeFilters.DynamicObject,
          userData = cast[DataPointer](obj.objectType)
        )[1], # get shape from tuple
        objectType = obj.objectType,
      )
    )

proc increaseCount*(state: GameState, objectType: DynamicObjectType) =
  state.contactCounts[objectType] = state.contactCounts.getOrDefault(objectType, 0) + 1

# Can't use CountTable because it doesn't allow decrement
proc decreaseCount*(state: GameState, objectType: DynamicObjectType) =
  state.contactCounts[objectType] = state.contactCounts.getOrDefault(objectType, 0) - 1

let postStepCallback: PostStepFunc = proc(space: Space, dynamicObjectShape: pointer, unused: pointer) {.cdecl raises: [].} =
  let state = cast[GameState](space.userData)
  let count = state.contactCounts.getOrDefault(DynamicObjectType.BowlingBall, -1) # todo do for every type
  

  var fastestAngularVelocity = 0f
  for obj in state.dynamicObjects:
    let shape = obj.shape
    if shape.kind == cpCircleShape: # todo check object type == bowling ball
      let circle = cast[CircleShape](shape)
      let angularVelocity = abs(circle.body.angularVelocity)
      if angularVelocity > fastestAngularVelocity:
        fastestAngularVelocity = angularVelocity

  let shouldPlay = count >= 1 and fastestAngularVelocity > 0.1f
  if bowlingBallRollPlayer.isNil:
    bowlingBallRollPlayer = getOrLoadSamplePlayer(SampleId.BowlingBallRolling)
  if shouldPlay and not bowlingBallRollPlayer.isPlaying:
    print "starting sound"
    bowlingBallRollPlayer.play(0, 1f)
  elif not shouldPlay and bowlingBallRollPlayer.isPlaying:
    print "stopping sound", count
    bowlingBallRollPlayer.stop()
  
  let targetRate = clamp(fastestAngularVelocity, 0.5f, 1.3f)
  let newRate = lerp(bowlingBallRollPlayer.rate, targetRate, 0.1f)
  bowlingBallRollPlayer.rate = newRate
  print "postStepCallback: ", count, fastestAngularVelocity, bowlingBallRollPlayer.rate

let collisionBeginFunc*: CollisionBeginFunc = proc(arb: Arbiter; space: Space; unused: pointer): bool {.cdecl.} =
  let state = cast[GameState](space.userData)
  var 
    shapeA: Shape
    shapeB: Shape
  arb.shapes(addr(shapeA), addr(shapeB))

  let objectType = cast[DynamicObjectType](shapeA.userData)

  print "collisionBeginFunc: ", objectType, shapeB.collisionType.repr
  state.increaseCount(objectType)
  
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

  let objectType = cast[DynamicObjectType](shapeA.userData)

  print "collisionPostSolveFunc: ", objectType, shapeB.collisionType.repr
  
  discard space.addPostStepCallback(
    postStepCallback,
    shapeA,
    postStepCallback # key for the post step callback, only called once per step, even if multiple collisions
  )


let collisionSeparateFunc*: CollisionSeparateFunc = proc(arb: Arbiter; space: Space; unused: pointer) {.cdecl.} =
  let state = cast[GameState](space.userData)
  var 
    shapeA: Shape
    shapeB: Shape
  arb.shapes(addr(shapeA), addr(shapeB))

  let objectType = cast[DynamicObjectType](shapeA.userData)

  print "collisionSeparateFunc: ", objectType, shapeB.collisionType.repr
  state.decreaseCount(objectType)

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
  if not bowlingBallRollPlayer.isNil:
    bowlingBallRollPlayer.stop()

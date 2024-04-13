{.push raises: [].}

import playdate/api
import math
import options
import chipmunk7
import game_types, graphics_types, shared_types
import game_bike, game_finish
import graphics_utils
import chipmunk_utils
import utils
import globals
import cache/bitmaptable_cache
import lcd_patterns

const
  swingArmChassisAttachmentOffset = v(0.0, 5.0)
  frontForkChassisAttachmentOffset = v(15.0, -3.0)
  forkOutlineWidth: int32 = 4'i32
  patternSize: int32 = 8'i32

var
  bikeChassisImageTable: AnnotatedBitmapTable
  bikeWheelImageTable: AnnotatedBitmapTable

  riderTorsoImageTable: AnnotatedBitmapTable
  riderHeadImageTable: AnnotatedBitmapTable
  riderUpperArmImageTable: AnnotatedBitmapTable
  riderLowerArmImageTable: AnnotatedBitmapTable
  riderUpperLegImageTable: AnnotatedBitmapTable
  riderLowerLegImageTable: AnnotatedBitmapTable
  killerImageTable: AnnotatedBitmapTable
  gravityImageTable: AnnotatedBitmapTable
  coinImage: LCDBitmap
  starImage: LCDBitmap
  gridImage: LCDBitmap

  # pre-allocated vars for drawing
  swingArmAttachmentScreenPos: Vect
  frontForkAttachmentScreenPos: Vect


proc initGameView*() =
  if bikeChassisImageTable != nil: return # already initialized

  bikeChassisImageTable = getOrLoadBitmapTable(BitmapTableId.BikeChassis)
  bikeWheelImageTable = getOrLoadBitmapTable(BitmapTableId.BikeWheel)
  riderTorsoImageTable = getOrLoadBitmapTable(BitmapTableId.RiderTorso)
  riderHeadImageTable = getOrLoadBitmapTable(BitmapTableId.RiderHead)
  riderUpperArmImageTable = getOrLoadBitmapTable(BitmapTableId.RiderUpperArm)
  riderLowerArmImageTable = getOrLoadBitmapTable(BitmapTableId.RiderLowerArm)
  riderUpperLegImageTable = getOrLoadBitmapTable(BitmapTableId.RiderUpperLeg)
  riderLowerLegImageTable = getOrLoadBitmapTable(BitmapTableId.RiderLowerLeg)
  killerImageTable = getOrLoadBitmapTable(BitmapTableId.Killer)
  gravityImageTable = getOrLoadBitmapTable(BitmapTableId.Gravity)
  initGameFinish()

  try:
    coinImage = gfx.newBitmap("images/coin")
    starImage = gfx.newBitmap("images/star")
    gridImage = gfx.newBitmap(displaySize.x.int32, displaySize.y.int32, gridPattern)
  except:
    echo getCurrentExceptionMsg()

proc drawCircle(camera: Camera, pos: Vect, radius: float, angle: float, color: LCDColor) =
  # covert from center position to top left
  let drawPos = pos - camera
  let x = (drawPos.x - radius).toInt
  let y = (drawPos.y - radius).toInt
  let size: int = (radius * 2f).toInt
  # angle is in radians, convert to degrees
  let deg = radTodeg(angle)
  gfx.drawEllipse(x,y,size, size, 1, deg+10, deg + 350, color);

proc drawSegment(camera: Camera, segment: SegmentShape, color: LCDColor) =
  let drawAPos = segment.a - camera
  let drawBPos = segment.b - camera
  # gfx.drawLine(drawAPos.x.toInt, drawAPos.y.toInt, drawBPos.x.toInt, drawBPos.y.toInt, 1, color);
  gfx.drawLine(drawAPos.x.int32, drawAPos.y.int32, drawBPos.x.int32, drawBPos.y.int32, 1, color);

proc shapeIter(shape: Shape, data: pointer) {.cdecl.} =
  let state = cast[ptr GameState](data)
  let camera = state.camera
  if shape.kind == cpCircleShape:
    let circle = cast[CircleShape](shape)
    drawCircle(camera, circle.body.position + circle.offset, circle.radius, circle.body.angle, kColorBlack)
  elif shape.kind == cpSegmentShape:
    let segment = cast[SegmentShape](shape)
    drawSegment(camera, segment, kColorBlack)
  elif shape.kind == cpPolyShape:
    let poly = cast[PolyShape](shape)
    let numVerts = poly.count
    for i in 0 ..< numVerts:
      let a = localToWorld(poly.body, poly.vert(i)) - camera
      let b = localToWorld(poly.body, poly.vert((i+1) mod numVerts)) - camera
      gfx.drawLine(a.x.toInt, a.y.toInt, b.x.toInt, b.y.toInt, 1, kColorBlack);

proc constraintIter(constraint: Constraint, data: pointer) {.cdecl.} =
  let state = cast[ptr GameState](data)
  let camera = state.camera
  if constraint.isGrooveJoint:
    # discard
    let groove = cast[GrooveJoint](constraint)
    let a = localToWorld(groove.bodyA, groove.grooveA) - camera
    let b = localToWorld(groove.bodyA, groove.grooveB) - camera
    gfx.drawLine(a.x.toInt, a.y.toInt, b.x.toInt, b.y.toInt, 1, kColorBlack);
  elif constraint.isDampedSpring:
    let spring = cast[DampedSpring](constraint)
    let a = localToWorld(spring.bodyA, spring.anchorA) - camera
    let b = localToWorld(spring.bodyB, spring.anchorB) - camera
    gfx.drawLine(a.x.toInt, a.y.toInt, b.x.toInt, b.y.toInt, 1, kColorBlack);
  elif constraint.isDampedRotarySpring:
    let spring = cast[DampedRotarySpring](constraint)
    let a = localToWorld(spring.bodyA, vzero) - camera
    let b = localToWorld(spring.bodyB, vzero) - camera
    gfx.drawLine(a.x.toInt, a.y.toInt, b.x.toInt, b.y.toInt, 1, kColorBlack);

proc initGameBackground*(state: GameState) =
  let level = state.level
  state.background = gfx.newBitmap(
    level.size.x, level.size.y, kColorWhite
  )

  gfx.pushContext(state.background)

  let terrainPolygons = level.terrainPolygons
  for polygon in level.terrainPolygons:
    gfx.fillPolygon(polygon.vertices, polygon.fill, kPolygonFillNonZero)
    drawPolygon(polygon.vertices)
  # for some reason, level.terrainPolygons is modified by calling gfx.fillPolygon
  # as a workaround, we re-copy the data back to the level
  level.terrainPolygons = terrainPolygons

  gfx.popContext()

# proc offset(vertices: seq[Vertex], off: Vertex): seq[Vertex] =
#   vertices.map(vertex => (
#     (vertex[0] - off[0]),
#     (vertex[1] - off[1])
#   ))

proc drawRotated(table: AnnotatedBitmapTable, center: Vect, angle: float32, driveDirection: DriveDirection) {.inline.} =
  table.drawRotated(
    center, 
    (if driveDirection == DD_LEFT: -angle else: angle),
    (if driveDirection == DD_LEFT: kBitmapFlippedX else: kBitmapUnflipped)
  )

proc drawRotated(table: AnnotatedBitmapTable, body: Body, state: GameState, inverse: bool = false) {.inline.} =
  let driveDirection = state.driveDirection
  table.drawRotated(
    body.position - state.camera, 
    (if driveDirection == DD_LEFT: -body.angle else: body.angle),
    (if driveDirection == DD_LEFT: kBitmapFlippedX else: kBitmapUnflipped)
  )

proc drawBikeForks*(state: GameState) =
  let chassis = state.chassis
  let camera = state.camera
  let driveDirection = state.driveDirection

  if state.gameResult.isSome and state.gameResult.get.resultType == GameResultType.GameOver:
    #drawLineOutlined from top of forkArm to bottom of forkArm
    let forkArm = state.forkArm
    let forkArmTopCenter = localToWorld(forkArm, forkArmTopCenterOffset) - camera
    let forkArmBottomCenter = localToWorld(forkArm, forkArmBottomCenterOffset) - camera
    drawLineOutlined(
      forkArmTopCenter,
      forkArmBottomCenter,
      forkOutlineWidth,
      kColorWhite,
    )

    # #drawLineOutlined from left of swingArm to right of swingArm
    let swingArm = state.swingArm
    let swingArmLeftCenter = localToWorld(swingArm, v(-halfSwingArmWidth, 0.0)) - camera
    let swingArmRightCenter = localToWorld(swingArm, v(halfSwingArmWidth, 0.0)) - camera
    drawLineOutlined(
      swingArmLeftCenter,
      swingArmRightCenter,
      forkOutlineWidth,
      kColorWhite,
    )
  else:
    let rearWheel = state.rearWheel
    let frontWheel = state.frontWheel
    let rearWheelScreenPos = rearWheel.position - camera
    let frontWheelScreenPos = frontWheel.position - camera
    # swingArm
    swingArmAttachmentScreenPos =
      localToWorld(chassis, swingArmChassisAttachmentOffset.transform(driveDirection)) - camera
    drawLineOutlined(
      swingArmAttachmentScreenPos,
      rearWheelScreenPos,
      forkOutlineWidth,
      kColorWhite,
    )

    # frontFork
    frontForkAttachmentScreenPos =
      localToWorld(chassis, frontForkChassisAttachmentOffset.transform(driveDirection)) - camera
    drawLineOutlined(
      frontForkAttachmentScreenPos,
      frontWheelScreenPos,
      forkOutlineWidth,
      kColorWhite,
    )

const
  rotationIndicatorRadius = 16'i32
  rotationIndicatorSize = rotationIndicatorRadius * 2'i32
  rotationIndicatorWidthDegrees = 6f

proc drawRotationForceIndicator(center: Vertex, forceDegrees: float32) =
  let
    x = center[0] - rotationIndicatorRadius
    y = center[1] - rotationIndicatorSize
  # total rotation range indicator
  gfx.drawEllipse(
    x, y, rotationIndicatorSize, rotationIndicatorSize, 
    3, 
    315, 45, 
    kColorBlack
  )
  # current rotation indicator
  gfx.drawEllipse(
    x,y - 3'i32,rotationIndicatorSize,rotationIndicatorSize,
    9, 
    forceDegrees - rotationIndicatorWidthDegrees, forceDegrees + rotationIndicatorWidthDegrees, 
    kColorXOR
  )

method getBitmap(asset: Asset, frameCounter: int32): LCDBitmap {.base.} =
  print("getImage not implemented for: ", repr(asset))
  return fallbackBitmap()

method getBitmap(asset: Texture, frameCounter: int32): LCDBitmap =
  return asset.image

method getBitmap(asset: Animation, frameCounter: int32): LCDBitmap =
  return asset.bitmapTable.getBitmap((frameCounter div 2'i32) mod asset.frameCount)

proc drawPlayer(state: GameState) =
  let chassis = state.chassis
  let camera = state.camera
  let driveDirection = state.driveDirection

  # wheels
  let frontWheel = state.frontWheel
  let frontWheelScreenPos = frontWheel.position - camera
  bikeWheelImageTable.drawRotated(frontWheelScreenPos, frontWheel.angle, driveDirection)
  let rearWheel = state.rearWheel
  let rearWheelScreenPos = rearWheel.position - camera
  bikeWheelImageTable.drawRotated(rearWheelScreenPos, rearWheel.angle, driveDirection)

  gfx.setLineCapStyle(kLineCapStyleRound)

  drawBikeForks(state)

  # chassis
  let chassisScreenPos = chassis.position - camera
  bikeChassisImageTable.drawRotated(chassisScreenPos, chassis.angle, driveDirection)

  # rider

  let riderHead = state.riderHead
  let riderHeadScreenPos = riderHead.position - camera
  if state.finishFlipDirectionAt.isSome:
    # flip rider head in direction of new DriveDirection when upperLeg has rotated past 0 degrees
    let flipThreshold = ((state.riderUpperLeg.angle - chassis.angle).signbit != state.driveDirection.signbit)
    let flipDirection = if flipThreshold: state.driveDirection else: -state.driveDirection
    riderHeadImageTable.drawRotated(riderHeadScreenPos, riderHead.angle, flipDirection)
  else:
    riderHeadImageTable.drawRotated(riderHead, state)

  var chassisTorque = 0.0
  if state.attitudeAdjust.isSome:
    chassisTorque = state.lastTorque

  let chassisTorqueDegrees = chassisTorque / 1_000f
  drawRotationForceIndicator(
    riderHeadScreenPos.toVertex,
    chassisTorqueDegrees
  )

  riderTorsoImageTable.drawRotated(state.riderTorso, state)
  riderUpperLegImageTable.drawRotated(state.riderUpperLeg, state)
  riderLowerLegImageTable.drawRotated(state.riderLowerLeg, state)
  riderUpperArmImageTable.drawRotated(state.riderUpperArm, state)
  riderLowerArmImageTable.drawRotated(state.riderLowerArm, state)

proc drawGame*(statePtr: ptr GameState) =
  let state = statePtr[]
  let level = state.level
  let camera = state.camera
  let camVertex = camera.toVertex()

  if debugDrawLevel:
    state.background.draw(-camVertex.x, -camVertex.y, kBitmapUnflipped)
  else:
    gfx.clear(kColorWhite)

  # draw grid
  if debugDrawGrid:
    gfx.setDrawMode(kDrawmodeWhiteTransparent)
    gridImage.draw(-camVertex[0] mod patternSize, -camVertex[1] mod patternSize, kBitmapUnflipped)
    gfx.setDrawMode(kDrawmodeCopy)

  if debugDrawTextures:
    # assets
    let frameCounter: int32 = state.frameCounter
    for asset in level.assets:
      let assetScreenPos = asset.position - camVertex
      asset.getBitmap(frameCounter).draw(assetScreenPos[0], assetScreenPos[1], asset.flip)

    # coins
    for coin in state.remainingCoins:
      let coinScreenPos = coin.position - camVertex
      coinImage.draw(coinScreenPos[0], coinScreenPos[1], kBitmapUnflipped)

    # star
    if state.remainingStar.isSome:
      let starScreenPos = state.remainingStar.get - camVertex
      starImage.draw(starScreenPos[0], starScreenPos[1], kBitmapUnflipped)


    # killer
    for killer in state.killers:
      let killerScreenPos = killer.position - camera
      killerImageTable.drawRotated(killerScreenPos, killer.angle)

    drawFinish(state)

  if debugDrawPlayer:
    drawPlayer(state)

  if debugDrawShapes:
    eachShape(statePtr.space, shapeIter, statePtr)

  if debugDrawConstraints:
    eachConstraint(statePtr.space, constraintIter, statePtr)
    let forkImpulse: int32 = state.forkArmSpring.impulse.int32
    gfx.fillRect(300, 50, 10, forkImpulse, kColorBlack)

  if state.time < 0.5:
    let messageY = (state.riderHead.position.y - camera.y - 26.0).int32
    if not state.isGameStarted:
      gfx.drawTextAligned("Ready?", 200, messageY)
    else:
      gfx.drawTextAligned("Go!", 200, messageY)
  

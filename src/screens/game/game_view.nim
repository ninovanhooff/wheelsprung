{.push locks:0.}

import playdate/api
import math
import std/sequtils
import std/sugar
import options
import chipmunk7
import game_types, graphics_types
import graphics_utils
import chipmunk_utils
import globals

const
  swingArmChassisAttachmentOffset = v(0.0, 5.0)
  frontForkChassisAttachmentOffset = v(15.0, -3.0)
  patternSize: int32 = 8'i32

let
  bgPattern: LCDPattern = makeLCDOpaquePattern(0x7F.uint8, 0xFF.uint8, 0xFF.uint8, 0xFF.uint8, 0xFF.uint8, 0xFF.uint8, 0xFF.uint8, 0xFF.uint8)

var
  bikeChassisImageTable: LCDBitmapTable
  bikeWheelImageTable: LCDBitmapTable

  riderTorsoImageTable: LCDBitmapTable
  riderHeadImageTable: LCDBitmapTable
  riderUpperArmImageTable: LCDBitmapTable
  riderLowerArmImageTable: LCDBitmapTable
  riderUpperLegImageTable: LCDBitmapTable
  riderLowerLegImageTable: LCDBitmapTable
  killerImageTable: LCDBitmapTable
  trophyImageTable: LCDBitmapTable
  coinImage: LCDBitmap
  bgImage: LCDBitmap

  # pre-allocated vars for drawing
  swingArmAttachmentScreenPos: Vect
  frontForkAttachmentScreenPos: Vect


proc initGameView*() =
  try:
    bikeChassisImageTable = gfx.newBitmapTable("images/bike-chassis")
    bikeWheelImageTable = gfx.newBitmapTable("images/bike-wheel")
    riderTorsoImageTable = gfx.newBitmapTable("images/rider/torso")
    riderHeadImageTable = gfx.newBitmapTable("images/rider/head")
    riderUpperArmImageTable = gfx.newBitmapTable("images/rider/upper-arm")
    riderLowerArmImageTable = gfx.newBitmapTable("images/rider/lower-arm")
    riderUpperLegImageTable = gfx.newBitmapTable("images/rider/upper-leg")
    riderLowerLegImageTable = gfx.newBitmapTable("images/rider/lower-leg")
    killerImageTable = gfx.newBitmapTable("images/killer/killer")
    trophyImageTable = gfx.newBitmapTable("images/trophy")

    coinImage = gfx.newBitmap("images/coin")

    bgImage = gfx.newBitmap(displaySize.x.int32, displaySize.y.int32, bgPattern)
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


proc offset(polygon: Polygon, off: Vertex): Polygon =
  polygon.map(vertex => [
    (vertex[0] - off[0]), 
    (vertex[1] - off[1])
    ])

proc drawTerrain(camVertex: Vertex, terrainPolygons: seq[Polygon]) =
  for polygon in terrainPolygons:
    # todo optimize: only draw if polygon is visible and not drawn to offscreen buffer yet
    gfx.fillPolygon(polygon.offset(camVertex), kColorBlack, kPolygonFillNonZero)

proc drawRotated(table: LCDBitmapTable, center: Vect, angle: float32, driveDirection: DriveDirection) {.inline.} =
  table.drawRotated(
    center, 
    (if driveDirection == DD_LEFT: -angle else: angle),
    (if driveDirection == DD_LEFT: kBitmapFlippedX else: kBitmapUnflipped)
  )

proc drawRotated(table: LCDBitmapTable, body: Body, state: GameState, inverse: bool = false) {.inline.} =
  let driveDirection = state.driveDirection
  table.drawRotated(
    body.position - state.camera, 
    (if driveDirection == DD_LEFT: -body.angle else: body.angle),
    (if driveDirection == DD_LEFT: kBitmapFlippedX else: kBitmapUnflipped)
  )

proc drawGame*(statePtr: ptr GameState) =
  let state = statePtr[]
  let level = state.level
  let chassis = state.chassis
  let camera = state.camera
  let camVertex = camera.toVertex()
  let driveDirection = state.driveDirection

  playdate.graphics.clear(kColorWhite)

  if debugDrawLevel:
    drawTerrain(camVertex, level.terrainPolygons)

  if debugDrawTextures:
    # wheels
    let frontWheel = state.frontWheel
    let frontWheelScreenPos = frontWheel.position - camera
    bikeWheelImageTable.drawRotated(frontWheelScreenPos, frontWheel.angle, driveDirection)
    let rearWheel = state.rearWheel
    let rearWheelScreenPos = rearWheel.position - camera
    bikeWheelImageTable.drawRotated(rearWheelScreenPos, rearWheel.angle, driveDirection)
    
    gfx.setLineCapStyle(kLineCapStyleRound)

    # swingArm
    swingArmAttachmentScreenPos = 
      localToWorld(chassis, swingArmChassisAttachmentOffset.transform(driveDirection)) - camera
    drawLineOutlined(
      swingArmAttachmentScreenPos, 
      rearWheelScreenPos, 
      4, 
      kColorWhite, 
    )

    # frontFork
    frontForkAttachmentScreenPos = 
      localToWorld(chassis, frontForkChassisAttachmentOffset.transform(driveDirection)) - camera
    drawLineOutlined(
      frontForkAttachmentScreenPos, 
      frontWheelScreenPos, 
      4, 
      kColorWhite, 
    )

    # chassis
    let chassisScreenPos = chassis.position - camera
    bikeChassisImageTable.drawRotated(chassisScreenPos, chassis.angle, driveDirection)

    # rider
    
    let riderHead = state.riderHead    
    if state.finishFlipDirectionAt.isSome:
      # flip rider head in direction of new DriveDirection when upperLeg has rotated past 0 degrees
      let flipThreshold = ((state.riderUpperLeg.angle - chassis.angle).signbit != state.driveDirection.signbit)
      let flipDirection = if flipThreshold: state.driveDirection else: -state.driveDirection
      let riderHeadScreenPos = riderHead.position - camera
      riderHeadImageTable.drawRotated(riderHeadScreenPos, riderHead.angle, flipDirection)
    else:
      riderHeadImageTable.drawRotated(riderHead, state)
    
    
    riderTorsoImageTable.drawRotated(state.riderTorso, state)
    riderUpperArmImageTable.drawRotated(state.riderUpperArm, state)
    riderLowerArmImageTable.drawRotated(state.riderLowerArm, state)
    riderUpperLegImageTable.drawRotated(state.riderUpperLeg, state)
    riderLowerLegImageTable.drawRotated(state.riderLowerLeg, state)

    # coins
    for coin in state.remainingCoins:
      let coinScreenPos = coin - camVertex
      coinImage.draw(coinScreenPos[0], coinScreenPos[1], kBitmapUnflipped)

    # killer
    for killer in state.killers:
      let killerScreenPos = killer.position - camera
      killerImageTable.drawRotated(killerScreenPos, killer.angle)

    # trophy
    let finishScreenPos = level.finishPosition - camVertex
    let finishTableIndex = if state.remainingCoins.len == 0: 1 else: 0
    trophyImageTable.getBitmap(finishTableIndex).draw(finishScreenPos[0], finishScreenPos[1], kBitmapUnflipped)
  
  if debugDrawShapes:
    bgImage.draw(-camVertex[0]mod patternSize, -camVertex[1] mod patternSize, kBitmapUnflipped)
    eachShape(statePtr.space, shapeIter, statePtr)

  if debugDrawConstraints:
    eachConstraint(statePtr.space, constraintIter, statePtr)
    let forkImpulse: int32 = state.forkArmSpring.impulse.int32
    gfx.fillRect(300, 50, 10, forkImpulse, kColorBlack)
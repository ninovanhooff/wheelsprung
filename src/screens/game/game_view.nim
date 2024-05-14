{.push raises: [].}

import playdate/api
import math
import options
import std/sequtils
import chipmunk7
import game_types
import common/[graphics_types, shared_types]
import game_bike, game_finish, game_ghost
import common/graphics_utils
import common/lcd_patterns
import game_debug_view
import chipmunk_utils
import common/utils
import globals
import cache/bitmaptable_cache
import screens/hit_stop/hit_stop_screen

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
  initGameGhost()

  try:
    coinImage = gfx.newBitmap("images/coin")
    starImage = gfx.newBitmap("images/star")
    gridImage = gfx.newBitmap(displaySize.x.int32, displaySize.y.int32, gridPattern)
  except:
    echo getCurrentExceptionMsg()

proc cameraShift(vertex: Vertex, cameraCenter: Vertex): Vertex {.inline.} =
  let perspectiveShiftVect: Vect = ((cameraCenter - vertex).toVect.vmult(0.05f))
  result = vertex + newBB(-5f, -5f, 5f, 5f).clampVect(perspectiveShiftVect).toVertex
  # print "cameraShift: ", vertex, " -> ", perspectiveShiftVect, "->", result

proc cameraShiftV(vertex: Vertex, cameraCenter: Vertex): Vect {.inline.} =
  let perspectiveShiftVect: Vect = ((cameraCenter - vertex).toVect.vmult(0.05f))
  result = newBB(-5f, -5f, 5f, 5f).clampVect(perspectiveShiftVect)
  # print "cameraShift: ", vertex, " -> ", perspectiveShiftVect, "->", result
    
proc drawGameBackground*(state: GameState) =
  let level = state.level
  let camVertex = state.camera.toVertex()
  gfx.clear(kColorWhite)

  gfx.setDrawOffset(-camVertex.x, -camVertex.y)

  # draw driving surface
  let camCenter = camVertex + halfDisplaySize.toVertex
  for polygon in level.terrainPolygons:
    var shiftedVertices = polygon.vertices.mapIt(it.cameraShift(camCenter))
    let shiftedVertices2 = shiftedVertices
    # for some reason, shiftedVertices is modified by calling gfx.fillPolygon.
    # As a workaround, we keep a duplicate of the data

    for i in 0..polygon.vertices.len - 2:
      # todo 2 shiftedVertices2 seq is not needed
      let v1 = polygon.vertices[i].toVect
      let v2 = polygon.vertices[i + 1].toVect
      ## https://stackoverflow.com/a/1243676/923557
      let vNormal = v(v2.y - v1.y, v1.x - v2.x)

      # todo can we use the same shiftedVertices2 seq?
      let sv1: Vect = cameraShiftV(shiftedVertices2[i], camCenter)
      let sv2: Vect = cameraShiftV(shiftedVertices2[i + 1], camCenter)
      let sSum = sv1 + sv2
      let dot = vNormal.vdot(sSum)
      print "dot for segment ", i, ":", dot, "shift: ", sv1, sv2, "normal: ", vNormal

      # todo levels: ccw winding order

      if dot < 0:
        gfx.fillPolygon([polygon.vertices[i], shiftedVertices2[i], shiftedVertices2[i+1], polygon.vertices[i + 1]], patGray, kPolygonFillNonZero)

    for i in 0..polygon.vertices.len - 1:
      # use the uncorrupted data to draw the perspective lines
      drawLine(shiftedVertices2[i], polygon.vertices[i], kColorBlack)
      gfx.drawTextAligned($i, polygon.vertices[i].x, polygon.vertices[i].y)



  if debugDrawPlayer:
    # draw solid terrain
    # todo use the state.background for this
    let terrainPolygons = level.terrainPolygons
    for polygon in level.terrainPolygons:
      gfx.fillPolygon(polygon.vertices, polygon.fill, kPolygonFillNonZero)
      drawPolyline(polygon.vertices)
    # for some reason, level.terrainPolygons is modified by calling gfx.fillPolygon.
    # As a workaround, we re-copy the data back to the level
    level.terrainPolygons = terrainPolygons

    for polyline in level.terrainPolylines:
      drawPolyline(polyline.vertices, polyline.thickness.int32)
      for vertex in polyline.vertices:
        # fill the gaps between sharp-angled line segments
        let radius = ((polyline.thickness * 0.75f) / 2f).roundToNearestInt()
        if radius > 0:
          fillCircle(vertex.x, vertex.y, radius)
  
  gfx.setDrawOffset(0,0)


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
  let frameCounter: int32 = state.frameCounter


  if debugDrawLevel:
    drawGameBackground(state)
  else:
    gfx.clear(kColorWhite)

  # draw grid
  if debugDrawGrid:
    gfx.setDrawMode(kDrawmodeWhiteTransparent)
    gridImage.draw(-camVertex[0] mod patternSize, -camVertex[1] mod patternSize, kBitmapUnflipped)
    gfx.setDrawMode(kDrawmodeCopy)

  if debugDrawTextures:
    # assets
    for asset in level.assets:
      let assetScreenPos = asset.position - camVertex
      asset.getBitmap(frameCounter).draw(assetScreenPos[0], assetScreenPos[1], asset.flip)

    # coins
    for coin in state.remainingCoins:
      let coinScreenPos = coin.position - camVertex
      if coin.count < 2:
        coinImage.draw(coinScreenPos[0], coinScreenPos[1], kBitmapUnflipped)
      else:
        gfx.drawTextAligned($coin.count, coinScreenPos[0] + 10, coinScreenPos[1])

    # star
    if state.remainingStar.isSome:
      let starScreenPos = state.remainingStar.get - camVertex
      starImage.draw(starScreenPos[0], starScreenPos[1], kBitmapUnflipped)


    # killer
    for killer in state.killers:
      let killerScreenPos = killer.position - camera
      killerImageTable.drawRotated(killerScreenPos, killer.angle)

    drawFinish(state)

  ## do not store poses in a variable to avoid copying
  if state.ghostPlayback.poses.high >= frameCounter:
    state.drawGhostPose(state.ghostPlayback.poses[frameCounter])


  if debugDrawPlayer:
    drawPlayer(state)

  if debugDrawShapes:
    eachShape(statePtr.space, shapeIter, statePtr)

  if debugDrawConstraints:
    eachConstraint(statePtr.space, constraintIter, statePtr)
    let forkImpulse: int32 = state.forkArmSpring.impulse.int32
    gfx.fillRect(300, 50, 10, forkImpulse, kColorBlack)

  if state.time < 500.Milliseconds:
    let messageY = (state.riderHead.position.y - camera.y - 26.0).int32
    if not state.isGameStarted:
      gfx.drawTextAligned("Ready?", 200, messageY)
    else:
      gfx.drawTextAligned("Go!", 200, messageY)
  
proc createHitstopScreen*(state: GameState, collisionShape: Shape): HitStopScreen =
  # Creates hitstopscreen without menu items
  drawGame(unsafeAddr state)
  let bitmapA = gfx.copyFrameBufferBitmap()

  let body = collisionShape.body
  let imageTable = if body == state.riderHead: riderHeadImageTable else: bikeWheelImageTable

  gfx.setDrawMode(kDrawmodeFillWhite)
  imageTable.drawRotated(body, state)
  gfx.setDrawMode(kDrawmodeCopy)

  let bitmapB = gfx.copyFrameBufferBitmap()
  return newHitStopScreen(
    bitmapA = bitmapA, 
    bitmapB = bitmapB, 
    maxShakeMagnitude = state.chassis.velocity.vlength * 0.2f
  )

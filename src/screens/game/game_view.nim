{.push raises: [].}

import playdate/api
import math
import options
import std/sequtils
import chipmunk7
import game_types
import common/graphics_types
import game_bike, game_finish, game_ghost, game_killer, game_coin, game_star, game_gravity_zone
import overlay/game_start_overlay_view
import overlay/game_ended_overlay
import overlay/game_replay_overlay
import game_dynamic_object
import common/graphics_utils
import common/lcd_patterns
import game_debug_view
import chipmunk/chipmunk_utils
import common/utils
import globals
import cache/bitmaptable_cache
import cache/font_cache
import screens/hit_stop/hit_stop_screen

const
  swingArmChassisAttachmentOffset = v(0.0, 5.0)
  frontForkChassisAttachmentOffset = v(15.0, -3.0)
  forkOutlineWidth: int32 = 4'i32
  patternSize: int32 = 8'i32

var
  isGameViewInitialized: bool = false
  bikeChassisImageTable: AnnotatedBitmapTable
  bikeWheelImageTable: AnnotatedBitmapTable

  riderTorsoImageTable: AnnotatedBitmapTable
  riderHeadImageTable: AnnotatedBitmapTable
  riderTailImageTable: AnnotatedBitmapTable
  riderUpperArmImageTable: AnnotatedBitmapTable
  riderLowerArmImageTable: AnnotatedBitmapTable
  riderUpperLegImageTable: AnnotatedBitmapTable
  riderLowerLegImageTable: AnnotatedBitmapTable
  gridImage: LCDBitmap

  smallFont: LCDFont

  # pre-allocated vars for drawing
  swingArmAttachmentScreenPos: Vect
  frontForkAttachmentScreenPos: Vect


proc initGameView*() =
  if isGameViewInitialized: return # already initialized

  bikeChassisImageTable = getOrLoadBitmapTable(BitmapTableId.BikeChassis)
  bikeWheelImageTable = getOrLoadBitmapTable(BitmapTableId.BikeWheel)
  riderTorsoImageTable = getOrLoadBitmapTable(BitmapTableId.RiderTorso)
  riderHeadImageTable = getOrLoadBitmapTable(BitmapTableId.RiderHead)
  riderTailImageTable = getOrLoadBitmapTable(BitmapTableId.RiderTail)
  riderUpperArmImageTable = getOrLoadBitmapTable(BitmapTableId.RiderUpperArm)
  riderLowerArmImageTable = getOrLoadBitmapTable(BitmapTableId.RiderLowerArm)
  riderUpperLegImageTable = getOrLoadBitmapTable(BitmapTableId.RiderUpperLeg)
  riderLowerLegImageTable = getOrLoadBitmapTable(BitmapTableId.RiderLowerLeg)

  isGameViewInitialized = true

proc getIsGameViewInitialized*(): bool =
  isGameViewInitialized

proc cameraShift(vertex: Vertex, cameraCenter: Vertex): Vertex {.inline.} =
  let perspectiveShift: Vertex = (cameraCenter - vertex) div 20
  result = perspectiveShift

proc initGeometryBackground(state: GameState)=
  let level = state.level
  state.background = gfx.newBitmap(
    level.size.x, level.size.y, kColorWhite
  )

  gfx.pushContext(state.background)

  let terrainPolygons = level.terrainPolygons
  for polygon in level.terrainPolygons:
    gfx.fillPolygon(polygon.vertices, polygon.fill, kPolygonFillNonZero)
    drawPolyline(polygon.vertices)
  # for some reason, level.terrainPolygons is modified by calling gfx.fillPolygon
  # as a workaround, we re-copy the data back to the level
  level.terrainPolygons = terrainPolygons

  for polyline in level.terrainPolylines:
    drawPolyline(polyline.vertices, polyline.thickness.int32)
    for vertex in polyline.vertices:
      # fill the gaps between sharp-angled line segments
      let radius = ((polyline.thickness * 0.75f) / 2f).roundToNearestInt()
      if radius > 0:
        fillCircle(vertex.x, vertex.y, radius)

  if smallFont.isNil:
    smallFont = getOrLoadFont(FontId.Roobert10Bold)
  gfx.setFont(smallFont)
  for text in level.texts:
    gfx.drawTextAligned(text.value, text.position.x, text.position.y, text.alignment)

  gfx.popContext()

proc initGameBackground*(state: GameState) =
  let level = state.level

  if state.hintsEnabled:
    try:
      state.background = gfx.newBitmap(state.level.hintsPath.get)
    except:
      print "Hints Image load failed:", getCurrentExceptionMsg()
  elif level.background.isSome:
    state.background = level.background.get
  else:
    state.initGeometryBackground()

proc drawPolygonDepth*(state: GameState) =
  let level = state.level
  let camVertex = state.camera.toVertex()

  gfx.setDrawOffset(-camVertex.x, -camVertex.y)

  # draw driving surface
  let viewport: LCDRect = offsetScreenRect(camVertex)
  let camCenter = camVertex + halfDisplaySize.toVertex + (x: 0'i32, y: -30'i32)
  for polygon in level.terrainPolygons:
    if not polygon.bounds.intersects(viewport):
      continue # skip drawing polygons that are not visible

    # todo make sure this is a reference, not a copy
    let polyVerts = polygon.vertices
    let shiftedVertices = polyVerts.mapIt(it.cameraShift(camCenter))

    for curIndex in 0..polyVerts.len - 2:
      let nextIndex = curIndex + 1

      if polygon.edgeIndices[curIndex]:
        continue

      let v1 = polyVerts[curIndex]
      let v2 = polyVerts[nextIndex]

      let dot = polygon.normals[curIndex].dotVertex(shiftedVertices[curIndex] + shiftedVertices[nextIndex])

      if dot < 0:
        gfx.fillPolygon(
          [
            v1, 
            v1 + shiftedVertices[curIndex], 
            v2 + shiftedVertices[nextIndex], 
            v2
          ], 
          patGrayTransparent, 
          kPolygonFillNonZero
        )

    if debugDrawShapes:
      for i in 0..polyVerts.len - 1:
        drawLine(polyVerts[i] + shiftedVertices[i], polyVerts[i], kColorBlack)
        gfx.drawTextAligned($i, polyVerts[i].x, polyVerts[i].y)
  
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

  if state.bikeConstraints.len == 0:
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

    # drawLineOutlined from left of swingArm to right of swingArm
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

  riderTailImageTable.drawRotated(state.riderTail, state)

  let riderHead = state.riderHead
  let riderHeadScreenPos = riderHead.position - camera
  if state.finishFlipDirectionAt.isSome:
    # flip rider head in direction of new DriveDirection when upperLeg has rotated past 0 degrees
    let flipThreshold = ((state.riderUpperLeg.angle - chassis.angle).signbit != state.driveDirection.signbit)
    let flipDirection = if flipThreshold: state.driveDirection else: -state.driveDirection
    riderHeadImageTable.drawRotated(riderHeadScreenPos, riderHead.angle, flipDirection)
  else:
    riderHeadImageTable.drawRotated(riderHead, state)

  riderUpperLegImageTable.drawRotated(state.riderUpperLeg, state)
  riderTorsoImageTable.drawRotated(state.riderTorso, state)
  riderLowerLegImageTable.drawRotated(state.riderLowerLeg, state)
  riderLowerArmImageTable.drawRotated(state.riderLowerArm, state)
  riderUpperArmImageTable.drawRotated(state.riderUpperArm, state)

proc drawGame*(statePtr: ptr GameState) =
  let state = statePtr[]
  let level = state.level
  let camera = state.camera
  let camVertex = camera.toVertex()
  let viewport: LCDRect = offsetScreenRect(camVertex)
  let cameraState = newCameraState(camera, camVertex, viewport, state.frameCounter)
  let frameCounter: int32 = state.frameCounter


  if debugDrawLevel:
    state.background.draw(-camVertex.x, -camVertex.y, kBitmapUnflipped)
  else:
    gfx.clear(kColorWhite)

  if level.background.isNone:
    state.drawPolygonDepth()

  # draw grid
  if debugDrawGrid:
    if gridImage.isNil:
      try:
        gridImage = gfx.newBitmap(displaySize.x.int32, displaySize.y.int32, gridPattern)
      except:
        print "Image load failed:", getCurrentExceptionMsg()
    gfx.setDrawMode(kDrawmodeWhiteTransparent)
    gridImage.draw(-camVertex[0] mod patternSize, -camVertex[1] mod patternSize, kBitmapUnflipped)
    gfx.setDrawMode(kDrawmodeCopy)

  state.drawDynamicObjects()

  if debugDrawTextures:
    # assets
    for asset in level.assets:
      drawAsset(asset, cameraState)

    # gravity zones
    drawGravityZones(state.gravityZones, state.gravityDirection, cameraState)

    # coins
    drawCoins(state.remainingCoins, cameraState)

    # star
    if state.remainingStar.isSome:
      drawStar(state.remainingStar.get, cameraState)


    # killer
    drawKillers(state.killers, camera)

    drawFinish(state, cameraState)

  ## do not store poses in a variable to avoid copying
  if state.ghostPlayback.poses.high >= frameCounter:
    state.drawGhostPose(state.ghostPlayback.poses[frameCounter])

  if debugDrawPlayer == false and frameCounter > 0:
    state.drawGhostPose(state.ghostRecording.poses[frameCounter - 1])

  if isGameViewInitialized and debugDrawPlayer:
    drawPlayer(state)

  if debugDrawShapes:
    eachShape(statePtr.space, shapeIter, statePtr)

  if debugDrawConstraints:
    eachConstraint(statePtr.space, constraintIter, statePtr)
    let forkImpulse: int32 = state.forkArmSpring.impulse.int32
    gfx.fillRect(300, 50, 10, forkImpulse, kColorBlack)

  # Game overlays
  if state.gameStartState.isSome:
    drawGameStartOverlay(state.gameStartState.get)

  if state.gameReplayState.isSome:
    state.drawGameReplayOverlay()
  elif state.gameResult.isSome:
    state.drawGameEndedOverlay()
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

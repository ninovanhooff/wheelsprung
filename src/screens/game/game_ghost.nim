import chipmunk7
import options
import playdate/api
import game_types, shared_types
import graphics_types
import graphics_utils
import cache/bitmaptable_cache
import game_debug_view
import utils

var
  riderGhostHeadImageTable: AnnotatedBitmapTable

proc initGameGhost*() =
  if riderGhostHeadImageTable != nil: return # already initialized

  riderGhostHeadImageTable = getOrLoadBitmapTable(BitmapTableId.RiderGhostHead)


proc drawGhostPose*(state: GameState, pose: PlayerPose) =
  let camera = state.camera
  drawRotated(
    riderGhostHeadImageTable,
    pose.headPose.position - camera,
    pose.headPose.angle,
    # todo flip
  )
  drawCircle(camera, pose.frontWheelPose.position, 10f, pose.frontWheelPose.angle, kColorBlack)
  drawCircle(camera, pose.rearWheelPose.position, 10f, pose.rearWheelPose.angle, kColorBlack)

proc updateGhostRecording*(state: GameState, coinProgress: float32) =
  ## takes coinProgress as arg to prevent dependency on game_coin.nim
  state.ghostRecording.coinProgress = coinProgress
  state.ghostRecording.gameResult = state.gameResult.get

proc pose(body: Body): Pose {.inline.} =
  result.position = body.position
  result.angle = body.angle

proc newPlayerPose*(state: GameState): PlayerPose =
  result.headPose = state.riderHead.pose
  result.frontWheelPose = state.frontWheel.pose
  result.rearWheelPose = state.rearWheel.pose

proc newGhost*(): Ghost =
  Ghost(
    poses: newSeqOfCap[PlayerPose](100), # 2 seconds at 50fps
    coinProgress: 0f,
    gameResult: fallbackGameResult
  )

proc pickBestGhost*(ghostA: Ghost, ghostB: Ghost): Ghost =
  ## When equal, ghostA is picked
  
  if ghostA.gameResult.resultType > ghostB.gameResult.resultType:
    print "ghostA is better because gameResult.resultType"
    return ghostA
  elif ghostA.gameResult.resultType < ghostB.gameResult.resultType:
    print "ghostB is better because gameResult.resultType"
    return ghostB
  elif ghostA.coinProgress > ghostB.coinProgress:
    print "ghostA is better because coinProgress"
    return ghostA
  elif ghostA.coinProgress < ghostB.coinProgress:
    print "ghostB is better because coinProgress"
    return ghostB
  elif ghostA.gameResult.time < ghostB.gameResult.time:
    print "ghostA is better because gameResult.time"
    return ghostA
  elif ghostA.gameResult.time > ghostB.gameResult.time:
    print "ghostB is better because gameResult.time"
    return ghostB
  else:
    # extremely unlikely, but possible
    print "picking ghostA because it's the default"
    return ghostA

proc addPose*(ghost: var Ghost, state: GameState) {.inline.} =
  ghost.poses.add(state.newPlayerPose)
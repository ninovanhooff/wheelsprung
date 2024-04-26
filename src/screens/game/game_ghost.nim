import chipmunk7
import playdate/api
import game_types
import game_debug_view

proc drawGhostPose*(state: GameState, pose: PlayerPose) =
  let camera = state.camera
  drawCircle(camera, pose.headPose.position, 10f, pose.headPose.angle, kColorBlack)
  drawCircle(camera, pose.frontWheelPose.position, 10f, pose.frontWheelPose.angle, kColorBlack)
  drawCircle(camera, pose.rearWheelPose.position, 10f, pose.rearWheelPose.angle, kColorBlack)

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
  )

proc addFrame*(ghost: var Ghost, state: GameState) {.inline.} =
  ghost.poses.add(state.newPlayerPose)
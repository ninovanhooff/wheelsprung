import chipmunk7
import playdate/api
import game_types
import game_debug_view
import utils

proc drawGhostPose*(state: GameState, pose: PlayerPose) =
  let camera = state.camera
  drawCircle(camera, pose.headPose.position, 10f, pose.headPose.angle, kColorBlack)
  drawCircle(camera, pose.frontWheelPose.position, 10f, pose.frontWheelPose.angle, kColorBlack)
  drawCircle(camera, pose.rearWheelPose.position, 10f, pose.rearWheelPose.angle, kColorBlack)

proc pose(body: Body): Pose {.inline.} = # todo not public
  let position = body.position
  result.position = body.position
  result.angle = body.angle

proc newPlayerPose*(state: GameState): PlayerPose =
  PlayerPose(
    headPose: state.riderHead.pose,
    frontWheelPose: state.frontWheel.pose,
    rearWheelPose: state.rearWheel.pose,
  )

proc newGhost*(): Ghost =
  Ghost(
    poses: @[],
    coinProgress: 0f,
  )

proc addFrame*(ghost: var Ghost, state: GameState) {.inline.} =
  print "poses len", ghost.poses.len
  ghost.poses.add(state.newPlayerPose)
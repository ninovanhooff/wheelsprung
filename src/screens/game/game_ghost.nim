import chipmunk7
import options
import sugar
import math
import playdate/api
import game_types
import common/shared_types
import common/graphics_types
import common/graphics_utils
import common/utils
import cache/bitmaptable_cache

type
  Comparable = concept x, y
    (x < y) is bool

  AnnotatedComparator = object of RootObj
    selector: proc(ghost: Ghost): float32 {.raises:[]}
    preferLargeValue: bool
    description: string

var
  riderGhostHeadImageTable: AnnotatedBitmapTable
  bikeGhostWheelImageTable: AnnotatedBitmapTable

let ghostComparators: seq[AnnotatedComparator] = @[
  AnnotatedComparator(
    selector: proc(ghost: Ghost): Comparable = ghost.gameResult.resultType.float32,
    preferLargeValue: true,
    description: "result type"
  ),
  AnnotatedComparator(
    selector: proc(ghost: Ghost): Comparable = ghost.coinProgress,
    preferLargeValue: true,
    description: "coin progress"
  ),
  AnnotatedComparator(
    selector: proc(ghost: Ghost): Comparable = ghost.gameResult.time.float32,
    preferLargeValue: false,
    description: "time"
  )
]


proc initGameGhost*() =
  if riderGhostHeadImageTable != nil: return # already initialized

  riderGhostHeadImageTable = getOrLoadBitmapTable(BitmapTableId.RiderGhostHead)
  bikeGhostWheelImageTable = getOrLoadBitmapTable(BitmapTableId.BikeGhostWheel)


proc drawGhostPose*(state: GameState, pose: PlayerPose) =
  let camera = state.camera
  drawRotated(
    riderGhostHeadImageTable,
    pose.headPose.position - camera,
    pose.headPose.angle,
    if pose.flipX: kBitmapFlippedX else: kBitmapUnflipped
  )
  # when the bike is flipped, the wheels don't need to be flipped, so we use kBitmapUnflipped
  drawRotated(
    bikeGhostWheelImageTable,
    pose.frontWheelPose.position - camera,
    pose.frontWheelPose.angle,
    kBitmapUnflipped
  )
  drawRotated(
    bikeGhostWheelImageTable,
    pose.rearWheelPose.position - camera,
    pose.rearWheelPose.angle,
    kBitmapUnflipped
  )

proc updateGhostRecording*(state: GameState, coinProgress: float32) =
  ## takes coinProgress as arg to prevent dependency on game_coin.nim
  state.ghostRecording.coinProgress = coinProgress
  state.ghostRecording.gameResult = state.gameResult.get(fallbackGameResult)

proc pose(body: Body): Pose {.inline.} =
  result = Pose(
    position: body.position,
    angle: body.angle
  )

proc newPlayerPose*(state: GameState): PlayerPose =
  result = PlayerPose(
    headPose: state.riderHead.pose,
    frontWheelPose: state.frontWheel.pose,
    rearWheelPose: state.rearWheel.pose,
    flipX: state.driveDirection.signbit # signbit is true if driveDirection is negative
  )

proc newGhost*(): Ghost =
  result = Ghost(
    poses: newSeqOfCap[PlayerPose](100), # 2 seconds at 50fps
    coinProgress: 0f,
    gameResult: fallbackGameResult
  )

proc compare(
  ghostA: Ghost, 
  ghostB: Ghost, 
  byKey: Ghost -> Comparable,
  preferLargeValue: bool = true
): Option[Ghost] =
  ## Returns the better ghost according to the comparator
  ## If ghosts are equal, ghostA is picked
  
  var keyA = byKey(ghostA)
  var keyB = byKey(ghostB)
  if keyB > keyA:
    return some(if preferLargeValue: ghostB else: ghostA)
  elif keyA > keyB:
    return some(if preferLargeValue: ghostA else: ghostB)
  else:
    return none(Ghost)


proc pickBestGhost*(ghostA: Ghost, ghostB: Ghost): Ghost {.raises:[].} =
  ## When equal, ghostA is picked
  
  for comparator in ghostComparators:
    let comparisionResult = compare(ghostA, ghostB, comparator.selector, comparator.preferLargeValue)
    if comparisionResult.isSome:
      if comparisionResult.get == ghostA:
        print "Picked ghostA by", comparator.description
      else:
        print "Picked ghostB by", comparator.description
      return comparisionResult.get

  print "Picked ghostA because no comparator could decide"
  return ghostA

proc addPose*(ghost: var Ghost, state: GameState) {.inline.} =
  ghost.poses.add(state.newPlayerPose)

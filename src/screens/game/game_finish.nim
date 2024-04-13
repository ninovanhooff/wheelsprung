import chipmunk7, chipmunk_utils
import utils
import math
import options
import playdate/api
import graphics_types, graphics_utils
import game_types
import cache/bitmaptable_cache


const
  vFinishSize = v(38.0, 38.0)
  vertFinishSize = vFinishSize.toVertex
  halfVertFinishSize = (vFinishSize / 2f).toVertex

  blinkerPeriod = 0.5
  halfBlinkerPeriod = blinkerPeriod / 2.0
  trophyBlinkerPos: Vertex = (360, 8)

var trophyImageTable: AnnotatedBitmapTable


proc initGameFinish*() =
  trophyImageTable = getOrLoadBitmapTable(BitmapTableId.Trophy)

proc addFinish*(space: Space, finish: Finish) =
  let vFinish = finish.toVect
  let bb = BB(
    l: vFinish.x, b: vFinish.y + vFinishSize.y, 
    r: vFinish.x + vFinishSize.x, t: vFinish.y
  )
  let shape = space.addShape(space.staticBody.newBoxShape(bb, 0.0))
  shape.filter = GameShapeFilters.Finish
  shape.collisionType = GameCollisionTypes.Finish

proc remainingRotations(state: GameState): int32 =
  let finishRequiredRotations = state.level.finishRequiredRotations
  if finishRequiredRotations > 0'i32:
    let currentRotations = abs(state.chassis.angle / TwoPi).int32
    return finishRequiredRotations - currentRotations
  else:
    return 0'i32

proc isFinishActivated*(state: GameState): bool =
  state.remainingCoins.len == 0 and state.remainingRotations == 0'i32

proc drawFinish*(state: GameState) =
  let level = state.level
  let camVertex = state.camera.toVertex

  # trophy itself
  let finishScreenPos: Vertex = level.finishPosition - camVertex
  let finishTableIndex: int32 = if state.isFinishActivated: 1'i32 else: 0'i32
  trophyImageTable.getBitmap(finishTableIndex).draw(finishScreenPos[0], finishScreenPos[1], kBitmapUnflipped)

  # Last coin collect blinker (HUD)
  if state.finishTrophyBlinkerAt.isSome:
    let blinkerOn: bool = state.time mod blinkerPeriod < halfBlinkerPeriod
    trophyImageTable.getBitmap(blinkerOn.int32).draw(trophyBlinkerPos[0], trophyBlinkerPos[1], kBitmapUnflipped)


  # Rotation count indicator
  let rotationsToDraw = state.remainingRotations
  if rotationsToDraw > 0:
    gfx.drawTextAligned(
      $rotationsToDraw & "X",
      finishScreenPos.x + halfVertFinishSize.x,
      finishScreenPos.y - 20'i32,
    )


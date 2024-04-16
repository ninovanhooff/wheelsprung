import chipmunk7
import math
import options
import playdate/api
import graphics_types, graphics_utils
import game_types
import cache/bitmaptable_cache


const
  vFinishSize = v(38.0, 38.0)

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

proc isFinishActivated*(state: GameState): bool {.inline.} =
  state.remainingCoins.len == 0

proc drawFinish*(state: GameState) =
  let level = state.level
  let camVertex = state.camera.toVertex

  # trophy itself
  if state.gameResult.isNone:
    let finishScreenPos: Vertex = level.finishPosition - camVertex
    let finishTableIndex: int32 = if state.isFinishActivated: 1'i32 else: 0'i32
    trophyImageTable.getBitmap(finishTableIndex).draw(finishScreenPos[0], finishScreenPos[1], kBitmapUnflipped)

  # Last coin collect blinker (HUD)
  if state.finishTrophyBlinkerAt.isSome:
    let blinkerOn: bool = state.time mod blinkerPeriod < halfBlinkerPeriod
    trophyImageTable.getBitmap(blinkerOn.int32).draw(trophyBlinkerPos[0], trophyBlinkerPos[1], kBitmapUnflipped)

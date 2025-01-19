import chipmunk7
import options
import playdate/api
import common/[graphics_types, graphics_utils]
import game_types
import common/shared_types
import cache/bitmaptable_cache


const
  vFinishSize = v(38.0, 38.0)

  blinkerPeriod = 500.Milliseconds
  halfBlinkerPeriod = blinkerPeriod div 2
  trophyBlinkerPos: Vertex = (360'i32, 8'i32)

var trophyImageTable: AnnotatedBitmapTable


proc initGameFinish*() =
  if trophyImageTable != nil: return
  trophyImageTable = getOrLoadBitmapTable(BitmapTableId.Trophy)

proc addFinish*(space: Space, finish: Finish) =
  let vFinish = finish.position.toVect
  let bb = BB(
    l: vFinish.x, b: vFinish.y + finishSizeF, 
    r: vFinish.x + finishSizeF, t: vFinish.y
  )
  let shape = space.addShape(space.staticBody.newBoxShape(bb, 0.0))
  shape.filter = GameShapeFilters.Finish
  shape.sensor = true
  shape.collisionType = GameCollisionTypes.Finish

proc isFinishActivated*(state: GameState): bool {.inline.} =
  state.remainingCoins.len == 0

proc drawFinish*(state: GameState, camState: CameraState) =
  let camVertex = camState.camVertex
  let finish = state.level.finish

  # trophy itself. Hide when level is successfully completed.
  if camState.viewport.intersects(finish.bounds) and (state.gameResult.isNone or state.gameResult.get.resultType != GameResultType.LevelComplete):
    let finishScreenPos: Vertex = finish.position - camVertex
    let finishTableIndex: int32 = if state.isFinishActivated: 1'i32 else: 0'i32
    initGameFinish()
    trophyImageTable.getBitmap(finishTableIndex).draw(finishScreenPos[0], finishScreenPos[1], finish.flip)

  # Last coin collect blinker (HUD)
  if state.finishTrophyBlinkerAt.isSome:
    let blinkerOn: bool = state.time mod blinkerPeriod < halfBlinkerPeriod
    initGameFinish()
    trophyImageTable.getBitmap(blinkerOn.int32).draw(trophyBlinkerPos[0], trophyBlinkerPos[1], finish.flip)

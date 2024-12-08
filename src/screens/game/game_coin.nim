import playdate/api
import chipmunk7
import std/options
import common/graphics_utils
import common/shared_types
import common/utils
import sound/game_sound
import game_types
import cache/bitmaptable_cache

var 
  coinsImageTable: AnnotatedBitmapTable

proc addCoins(space: Space, coins: seq[Coin]) =
  for index, coin in coins:
    let shape: Shape = newCircleShape(space.staticBody, coinRadius, toVect(coin.position) + vCoinOffset)
    shape.sensor = true # only detect collisions, don't apply forces to colliders
    shape.collisionType = GameCollisionTypes.Coin
    shape.filter = GameShapeFilters.Collectible
    shape.userData = cast[DataPointer](coin)
    discard space.addShape(shape)

proc totalCount*(coins: seq[Coin]): int32 =
  result = 0
  for coin in coins:
    result += coin.count

proc coinProgress*(state: GameState): float32 =
  let safeTotalCount: float32 = max(1f, state.level.coins.totalCount.float32) # avoid division by zero
  let coinProgress = 1f - (state.remainingCoins.totalCount.float32 / safeTotalCount)
  return coinProgress

# better deepCopy implementation: https://github.com/nim-lang/Nim/issues/23460
proc myDeepCopy[T](src: ref T): ref T =
  new(result)
  result[] = src[]

proc initGameCoin() =
  if coinsImageTable != nil: return
  coinsImageTable = getOrLoadBitmapTable(BitmapTableId.Nuts)

proc addGameCoins*(state: GameState) =
  # asssigment by copy
  state.remainingCoins = @[]
  for coin in state.level.coins:
    state.remainingCoins.add(myDeepCopy(coin))
  state.space.addCoins(state.remainingCoins)

proc drawCoins*(remainingCoins: seq[Coin], camState: CameraState) =
  let camVertex = camState.camVertex
  for coin in remainingCoins:
      if not camState.viewport.intersects(coin.bounds):
        continue

      initGameCoin()
      
      let coinScreenPos = coin.position - camVertex
      let coinIndex = (coin.coinIndex + coin.count) mod coinsImageTable.frameCount
      let coinBitmap = coinsImageTable.getBitmap(coinIndex)
      # animate highlight at 1/4 speed, starting from the coinIndex
      let highlightImage = getOrLoadBitmapTable(BitmapTableId.PickupHighlight).getBitmap(coinIndex + camState.frameCounter div 4)
      highlightImage.draw(coinScreenPos[0] - 5, coinScreenPos[1] - 5, kBitmapUnflipped)
      coinBitmap.draw(coinScreenPos[0], coinScreenPos[1], kBitmapUnflipped)

let coinPostStepCallback: PostStepFunc = proc(space: Space, coinShape: pointer, unused: pointer) {.cdecl raises: [].} =
  let state = cast[GameState](space.userData)
  let shape = cast[Shape](coinShape)
  var coin = cast[Coin](shape.userData)
  if state.time < coin.activeFrom:
    # print("coin activates at: " & repr(coin.activeFrom) & " current time: " & repr(state.time))
    return
  if coin.count > 1:
    coin.count -= 1
    coin.activeFrom = state.time + 2000.Milliseconds
    # print("new count for coin: " & repr(coin))
    playCoinSound(state.coinProgress)
    return

  # print("deleting coin: " & repr(coin))
  space.removeShape(shape)
  let deleteIndex = state.remainingCoins.find(coin)
  if deleteIndex == -1:
    print("coin not found in remaining coins: " & repr(coin))
  else:
    # print("deleting coin at index: " & repr(deleteIndex))
    state.remainingCoins.delete(deleteIndex)
    playCoinSound(state.coinProgress)

    if state.remainingCoins.len == 0:
      # print("all coins collected")
      state.finishTrophyBlinkerAt = some(state.time + 2500.Milliseconds)

let coinBeginFunc*: CollisionBeginFunc = proc(arb: Arbiter; space: Space; unused: pointer): bool {.cdecl.} =
  var 
    shapeA: Shape
    shapeB: Shape
  arb.shapes(addr(shapeA), addr(shapeB))
  # print("coin collision for arbiter" & " shapeA: " & repr(shapeA) & " shapeB: " & repr(shapeB))
  discard space.addPostStepCallback(coinPostStepCallback, shapeA, nil)
  false # don't process the collision further

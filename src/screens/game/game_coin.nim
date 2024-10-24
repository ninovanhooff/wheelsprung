import playdate/api
import chipmunk7
import common/graphics_utils
import game_types
import common/utils
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

proc initGameCoin*() =
  coinsImageTable = getOrLoadBitmapTable(BitmapTableId.Nuts)

proc addGameCoins*(state: GameState) =
  # asssigment by copy
  print "initGameCoins"
  state.remainingCoins = @[]
  for coin in state.level.coins:
    state.remainingCoins.add(myDeepCopy(coin))
  state.space.addCoins(state.remainingCoins)

proc drawCoins*(remainingCoins: seq[Coin], camVertex: Vertex) =
  let viewport = offsetScreenRect(camVertex)
  for coin in remainingCoins:
      if not viewport.intersects(coin.bounds):
        continue
      
      let coinScreenPos = coin.position - camVertex
      let coinIndex = (coin.coinIndex + coin.count) mod coinsImageTable.frameCount
      let coinBitmap = coinsImageTable.getBitmap(coinIndex)
      coinBitmap.draw(coinScreenPos[0], coinScreenPos[1], kBitmapUnflipped)

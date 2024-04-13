import chipmunk7
import graphics_utils
import game_types
import utils

const
  coinRadius = 10.0
  vCoinOffset = v(coinRadius, coinRadius)

proc addCoins(space: Space, coins: seq[Coin]) =
  for index, coin in coins:
    let shape: Shape = newCircleShape(space.staticBody, coinRadius, toVect(coin.position) + vCoinOffset)
    shape.sensor = true # only detect collisions, don't apply forces to colliders
    shape.collisionType = GameCollisionTypes.Coin
    shape.filter = GameShapeFilters.Collectible
    shape.userData = cast[DataPointer](coin)
    discard space.addShape(shape)

proc initGameCoins*(state: GameState) =
  # asssigment by copy
  print "initGameCoins"
  state.remainingCoins = @[]
  for coin in state.level.coins:
    state.remainingCoins.add(newCoin(coin.position, coin.count))
  state.space.addCoins(state.remainingCoins)

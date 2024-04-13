import chipmunk7
import graphics_utils
import game_types

const
  coinRadius = 10.0
  vCoinOffset = v(coinRadius, coinRadius)

proc initGameCoins*(state: GameState) =
  # asssigment by copy
  state.remainingCoins = state.level.coins

proc addCoins*(space: Space, coins: seq[Coin]) =
  for index, coin in coins:
    let shape: Shape = newCircleShape(space.staticBody, coinRadius, toVect(coin.position) + vCoinOffset)
    shape.sensor = true # only detect collisions, don't apply forces to colliders
    shape.collisionType = GameCollisionTypes.Coin
    shape.filter = GameShapeFilters.Collectible
    shape.userData = cast[DataPointer](index)
    discard space.addShape(shape)

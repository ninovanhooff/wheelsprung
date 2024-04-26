import math
import sugar
import utils
import options
import screens/game/game_types
import screens/game/game_coin

proc runTests*() =
    print "Test: Running tests..."
    
    assert normalizeAngle(0) == 0
    assert normalizeAngle(Pi32) == Pi32
    assert normalizeAngle(TwoPi) == 0f
    assert normalizeAngle(3 * Pi32).almostEqual(Pi32)
    assert normalizeAngle(-Pi32) == Pi32
    assert normalizeAngle(-2 * Pi32) == 0f
    assert normalizeAngle(-3 * Pi32).almostEqual(Pi32)

    assert roundToNearestInt(1305, 100) == 1300
    assert roundToNearestInt(1351, 100) == 1400

    assert lerp(0, 10, 0) == 0
    assert lerp(0, 10, 1) == 10
    assert lerp(0, 10, 0.5) == 5
    # test clamping
    assert lerp(0, 10, -1) == 0
    assert lerp(0, 10, 2) == 10

    assert @[1, 2, 3].findFirst(it => false).isNone
    assert @[1, 2, 3].findFirst(it => it == 2).isSome
    assert @[1, 2, 3].findFirst(it => it == 2).get == 2
    assert @[1, 2, 3].findFirst(it => it mod 2 == 1).get == 1 # should return first match if multiple
    assert @[1, 2, 3].findFirst(it => it == 2).get == 2
    assert @[1, 2, 3].findFirst(it => it == 5).isNone

    let coins: seq[Coin] = @[]
    let level: Level = Level(coins: coins)
    let state: GameState = GameState(
        remainingCoins : coins,
        level : level
    )
    assert state.coinProgress == 1f, "When level has no coins, progress should be 1"
    
    print "Test: Tests passed."

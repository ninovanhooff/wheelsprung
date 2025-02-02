import std/importutils

import screens/screen_types
import screens/game/game_screen {.all.}
import screens/game/game_level_loader
import screens/game/game_types
import navigation/screen

const testLevelPath = "/Users/ninovanhooff/PlaydateProjects/wheelsprung/scripts/gc_test/backflip_no_bg.wmj"

proc loadLevelTest() =
  discard loadLevel(testLevelPath)

proc gameStateTest() =
  let level = loadLevel(testLevelPath)
  for i in 1 .. 3:
    echo "==== run: ", i
    let gameState: GameState = newGameState(level = level)
    # let gameState: GameState = GameState(level : level)
    gameState.destroy()

proc gameScreenTest() =
  var gameScreen: GameScreen = newGameScreen(testLevelPath)
  echo "resume result", gameScreen.resume()
  for i in 1 .. 3:
    echo "==== restart game: ", i
    gameScreen.pause()
    gameScreen.setResult(ScreenResult(screenType: ScreenType.Game, restartGame: true))
    echo "resume result: ", gameScreen.resume()
  gameScreen.destroy()

proc performTest(procToTest: proc(), label: string = "") =
  var leaks: int = 0
  var allocDiff: AllocStats = getAllocStats()
  var beforeAllocStats: AllocStats = getAllocStats()
  var afterAllocStats: AllocStats = getAllocStats()
  
  GC_fullCollect()
  echo "====== run: Initial ===== ", label
  beforeAllocStats = getAllocStats()

  procToTest()
  GC_fullCollect()
  
  afterAllocStats = getAllocStats()
  allocDiff = afterAllocStats - beforeAllocStats
  privateAccess(AllocStats)
  leaks = allocDiff.allocCount - allocDiff.deallocCount
  echo "AllocStats Before", beforeAllocStats
  echo "AllocStats After", afterAllocStats
  echo "AllocStats Diff", allocDiff
  echo "Retained: ", leaks

  for i in 1 .. 3:
    echo "==== run: ", i, label
    beforeAllocStats = getAllocStats()
    procToTest()
    GC_fullCollect()
    afterAllocStats = getAllocStats()
    allocDiff = afterAllocStats - beforeAllocStats
    leaks = allocDiff.allocCount - allocDiff.deallocCount
    echo "AllocStats Before", beforeAllocStats
    echo "AllocStats After", afterAllocStats
    echo "AllocStats Diff", allocDiff
    echo "Leaks: ", leaks
    if leaks > 0:
      quit(1)

when isMainModule:
  performTest(loadLevelTest, "loadLevelTest")
  performTest(gameStateTest, "gameStateTest")
  performTest(gameScreenTest, "gameScreenTest")
  echo "All tests passed"


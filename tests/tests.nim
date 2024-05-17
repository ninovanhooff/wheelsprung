import math
import sugar
import common/utils
import common/graphics_utils
import options
import screens/game/game_types
import screens/game/game_coin
import playdate/api

import strformat, strutils, macros

## Inspired by https://github.com/xmonader/nim-minitest
template check*(exp:untyped, expected: untyped = true, failureMsg:string="FAILED", indent:uint=0): void =
  let indentationStr = repeat(' ', indent)
  let expStr: string = astToStr(exp)
  var msg: string
  if exp != expected:
    msg = indentationStr & expStr & " .. " & failureMsg & "\n (expected: " & astToStr(expected) & ", actual: " & $exp & ")"
  else:
    msg = indentationStr & expStr & " .. passed"

  print(msg) # replace this by your print function

proc runTests*() =
  print "======== Test: Running tests ========="

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


  check(1234.formatTime, "00:01.23")
  check(-1234.formatTime(signed = true), "-00:01.23")
  check(1234.formatTime(signed = true), "+00:01.23")

  var testBounds = LCDRect(left: 0, top: 0, right: 100, bottom: 100)
  check(testBounds.contains(newVertex(0, 0)))
  check(testBounds.contains(newVertex(100, 100)))
  check(testBounds.contains(newVertex(50, 50)))
  check(not testBounds.contains(newVertex(-1, 0)))
  check(not testBounds.contains(newVertex(101, 0)))
  
  testBounds.encapsulate(newVertex(105, 110))
  check(testBounds.contains(newVertex(3, 0)))
  check(testBounds.contains(newVertex(105, 109)))
  check(testBounds.contains(newVertex(105, 110)))
  check(not testBounds.contains(newVertex(105, 111)))


  print "======== Test: Tests Completed ========="

import chipmunk7
import math
import sugar
import common/shared_types
import common/utils
import common/graphics_utils
import common/level_utils
import options
import screens/game/game_types
import screens/game/game_coin
import screens/game/game_level_loader
import screens/game/input/game_input_recording

import minitest
import hashing_test

import playdate/api

import strutils

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
  assert @[1, 2, 3].findFirstIndexed(it => it == 2) == (1, some(2))
  assert @[1, 2, 3].findFirst(it => it == 5).isNone

  let coins: seq[Coin] = @[]
  let level: Level = Level(coins: coins)
  let state: GameState = GameState(
      remainingCoins : coins,
      level : level,
      inputProvider: newLiveInputProvider(),
  )
  assert state.coinProgress == 1f, "When level has no coins, progress should be 1"


  check(1234.formatTime, "00:01.23")
  check(-1234.formatTime(signed = true), "-00:01.23")
  check(1234.formatTime(signed = true), "+00:01.23")
  check(123484.formatTime(signed = true), "+02:03.48")

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

  let lcdRect1 = LCDRect(left: 0, top: 0, right: 100, bottom: 100)
  let lcdRect2 = LCDRect(left: 50, top: 50, right: 150, bottom: 150)
  let lcdRect3 = LCDRect(left: 150, top: 150, right: 250, bottom: 250)
  check(lcdRect1.intersects(lcdRect2))
  check(lcdRect2.intersects(lcdRect1))
  check(lcdRect1.intersects(lcdRect1))
  check(lcdRect2.intersects(lcdRect3))
  check(not lcdRect1.intersects(lcdRect3))
  check(not lcdRect3.intersects(lcdRect1))

  let expectPolygon = Polygon(
    vertices: @[newVertex(0, 0), newVertex(100, 0), newVertex(100, 100), newVertex(0, 100)],
    normals: @[newVertex(0, -100), newVertex(100, 0), newVertex(0, 100)],
    bounds: LCDRect(left: 0, top: 0, right: 100, bottom: 100),
    edgeIndices: @[false, false, false, false],
    fill: nil
  )

  let actualPolygon = newPolygon(
    vertices = @[newVertex(0, 0), newVertex(100, 0), newVertex(100, 100), newVertex(0, 100)],
    bounds = LCDRect(left: 0, top: 0, right: 100, bottom: 100),
  )
  
  check(expectPolygon, actualPolygon)
  check(actualPolygon.bounds, LCDRect(left: 0, top: 0, right: 100, bottom: 100))
  check(actualPolygon.vertices, @[newVertex(0, 0), newVertex(100, 0), newVertex(100, 100), newVertex(0, 100)])
  check(actualPolygon.normals, expectPolygon.normals)
  check(actualPolygon.edgeIndices, @[false, false, false, false])
  check(actualPolygon.edgeIndices[0], false)

  check(tiledRectPosToCenterPos(0, 0, 100, 100, 0), v(50, 50))
  check(tiledRectPosToCenterPos(0, 0, 100, 100, 45).toVertex, newVertex(0, 71))
  check(tiledRectPosToCenterPos(0, 0, 100, 100, -45).toVertex, newVertex(71, 0))
  check(tiledRectPosToCenterPos(0, 0, 100, 100, 90).toVertex, newVertex(-50, 50))
  check(tiledRectPosToCenterPos(0, 0, 100, 100, 180).toVertex, newVertex(-50, -50))
  check(tiledRectPosToCenterPos(0, 0, 100, 100, 270).toVertex, newVertex(50, -50))
  check(tiledRectPosToCenterPos(0, 0, 100, 100, -90).toVertex, newVertex(50, -50))
  check(tiledRectPosToCenterPos(0, 0, 100, 100, 360).toVertex, newVertex(50, 50))

  check("levels/tutorial_brake.wmj".nextLevelPath(), some("levels/tutorial_turn_around.wmj"))
  check("nonExisting.wmj".nextLevelPath(), none(Path))
  check("levels/level3.wmj".nextLevelPath(), none(Path))

  check rem(1, -4) == -3
  check rem(-1, 4) == 3
  check rem(-1, -4) == -1
  check rem(1, 4) == 1

  # test whether any of the buttons are pressed
  check ({kButtonB, kButtonA} * {kButtonB}).len > 0

  let inputRecording = newInputRecording()
  inputRecording.addInputFrame({kButtonA}, 0)
  let recordedInputProvider = RecordedInputProvider(recording: inputRecording)
  let frame0ButtonState = (
    current: {kButtonA},
    pushed: {kButtonA},
    released: {}
  ).PDButtonState
  check(recordedInputProvider.getButtonState(0), frame0ButtonState)
  inputRecording.addInputFrame({kButtonA}, 1)
  check(recordedInputProvider.getButtonState(1), (
    current: {kButtonA},
    pushed: {},
    released: {}
  ).PDButtonState)
  inputRecording.addInputFrame({kButtonB}, 2)
  check(recordedInputProvider.getButtonState(2), (
    current: {kButtonB},
    pushed: {kButtonB},
    released: {kButtonA}
  ).PDButtonState)
  inputRecording.addInputFrame({}, 3)
  check(recordedInputProvider.getButtonState(3), (
    current: {},
    pushed: {},
    released: {kButtonB}
  ).PDButtonState)
  inputRecording.addInputFrame({kButtonA, kButtonRight}, 4)
  check(recordedInputProvider.getButtonState(4), (
    current: {kButtonA, kButtonRight},
    pushed: {kButtonA, kButtonRight},
    released: {}
  ).PDButtonState)
  inputRecording.addInputFrame({kButtonA, kButtonLeft}, 5)
  check(recordedInputProvider.getButtonState(5), (
    current: {kButtonA, kButtonLeft},
    pushed: {kButtonLeft},
    released: {kButtonRight}
  ).PDButtonState)
  # earlier frames should not be affected
  check(recordedInputProvider.getButtonState(0), frame0ButtonState)


  testHashing()

  for i in countdown(5, 10):
    print "ERROR did not expect any invocation for invalid countdown range", i

  print "======== Test: Tests Completed ========="

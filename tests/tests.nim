import std/math
import std/strformat
import utils
import screens/game/game_input

proc testNotify(message: string): bool =
    print("Test: " & message)
    return true

proc testAttitudeAdjust(crankAngle, calibrationAngle, expectedAdjustment: float32): bool {.raises: [].} = 
    var adjustment = attitudeAdjustForCrankAngle(crankAngle, calibrationAngle)
    try:
        assert abs(adjustment - expectedAdjustment) < 0.001, &"Expected adjustment {expectedAdjustment} for crank {crankAngle}, calibration {calibrationAngle}, got {adjustment}"
    except ValueError:
        echo "Could not format test error string"
    return true

proc runTests*() =
    # All calls should be passed to assert, so that this proc gets optimized out in release builds

    assert testNotify "Running tests..."
    
    assert normalizeAngle(0) == 0
    assert normalizeAngle(PI) == PI
    assert normalizeAngle(2 * PI) == 0
    assert normalizeAngle(3 * PI) == PI
    assert normalizeAngle(-PI) == PI
    assert normalizeAngle(-2 * PI) == 0
    assert normalizeAngle(-3 * PI) == PI

    assert roundToNearest(1305, 100) == 1300
    assert roundToNearest(1351, 100) == 1400

    assert lerp(0, 10, 0) == 0
    assert lerp(0, 10, 1) == 10
    assert lerp(0, 10, 0.5) == 5
    # test clamping
    assert lerp(0, 10, -1) == 0
    assert lerp(0, 10, 2) == 10

    # test attitudeAdjustForCrankAngle

    # calibration angle is the neutral position
    assert testAttitudeAdjust(0f, 0f, 0f)
    assert testAttitudeAdjust(270f, 270f, 0f)
    assert testAttitudeAdjust(66.5f, 66.5f, 0f)
    assert testAttitudeAdjust(100f, 90f, 10f / 90f)
    assert testAttitudeAdjust(80f, 90f, -10f / 90f )
    assert testAttitudeAdjust(350f, 10f, -20f / 90f)
    assert testAttitudeAdjust(10f, 350f, 20f / 90f)

    # test 90 degree turns
    assert testAttitudeAdjust(0f, 270f, 1f)
    assert testAttitudeAdjust(315f, 270f, 0.5f)
    assert testAttitudeAdjust(180f, 270f, -1f)
    assert testAttitudeAdjust(0f, 90f, -1f)
    assert testAttitudeAdjust(180f, 90f, 1f)
    assert testAttitudeAdjust(180f, 0f, -2.0f)

    assert testAttitudeAdjust(0f, 180f, -2.0f)
    
    assert testNotify "Tests passed."
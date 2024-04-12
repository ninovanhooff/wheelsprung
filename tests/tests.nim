import std/math
import utils

proc runTests*() =
    print "Test: Running tests..."
    
    assert normalizeAngle(0) == 0
    assert normalizeAngle(Pi32) == Pi32
    assert normalizeAngle(TwoPi) == 0f
    assert normalizeAngle(3 * Pi32).almostEqual(Pi32)
    assert normalizeAngle(-Pi32) == Pi32
    assert normalizeAngle(-2 * Pi32) == 0f
    assert normalizeAngle(-3 * Pi32).almostEqual(Pi32)

    assert roundToNearest(1305, 100) == 1300
    assert roundToNearest(1351, 100) == 1400

    assert lerp(0, 10, 0) == 0
    assert lerp(0, 10, 1) == 10
    assert lerp(0, 10, 0.5) == 5
    # test clamping
    assert lerp(0, 10, -1) == 0
    assert lerp(0, 10, 2) == 10
    
    print "Test: Tests passed."

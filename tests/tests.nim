import std/math
import utils

proc testNotify(messag: string): bool =
    print("Test: " & messag)
    return true

proc runTests*() =
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
    
    assert testNotify "Tests passed."
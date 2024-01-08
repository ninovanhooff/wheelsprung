import chipmunk7

type Camera* = Vect

type DriveDirection* = float32

const DD_LEFT: DriveDirection = -1.0f
const DD_RIGHT: DriveDirection = 1.0f

type GameState* = ref object of RootObj
    space*: Space
    time*: float32
    attitudeAdjustForce*: float32
    camera*: Camera
    driveDirection*: DriveDirection

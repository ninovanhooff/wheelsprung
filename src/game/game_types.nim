import chipmunk7


type Camera* = Vect

type DriveDirection* = float32

const DD_LEFT*: DriveDirection = -1.0f
const DD_RIGHT*: DriveDirection = 1.0f

type
    Int32x2 = array[2, int32]
    Vertex* = Int32x2
    Polygon* = seq[Vertex]

type GameState* = ref object of RootObj
    space*: Space
    time*: float32
    attitudeAdjustForce*: float32
    camera*: Camera
    driveDirection*: DriveDirection

    # bodies
    backWheel*: Body
    frontWheel*: Body
    chassis*: Body
    swingArm*: Body
    forkArm*: Body

    # Level Objects
    groundPolygons*: seq[Polygon]

    bikeConstraints*: seq[Constraint]

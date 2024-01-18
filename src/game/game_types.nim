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

    initialChassisPosition*: Vect

    # bike bodies
    backWheel*: Body
    frontWheel*: Body
    chassis*: Body
    swingArm*: Body
    forkArm*: Body

    # rider bodies
    riderHead*: Body
    riderTorso*: Body
    riderUpperArm*: Body
    riderLowerArm*: Body
    riderUpperLeg*: Body
    riderLowerLeg*: Body
    # keep in sync with getRiderBodies()

    # Level Objects
    groundPolygons*: seq[Polygon]

    bikeConstraints*: seq[Constraint]
    riderConstraints*: seq[Constraint]

proc getRiderBodies*(state: GameState): seq[Body] =
    result = @[
        state.riderHead,
        state.riderTorso,
        state.riderUpperArm,
        state.riderLowerArm,
        state.riderUpperLeg,
        state.riderLowerLeg,
    ]

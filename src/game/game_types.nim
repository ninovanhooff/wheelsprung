import chipmunk7
import options


type Camera* = Vect

type DriveDirection* = Float

const DD_LEFT*: DriveDirection = -1.0
const DD_RIGHT*: DriveDirection = 1.0

type
    Int32x2 = array[2, int32]
    Vertex* = Int32x2
    Polygon* = seq[Vertex]
    Time* = float32

type Level* = ref object of RootObj
    groundPolygons*: seq[Polygon]
    initialChassisPosition*: Vect
    initialDriveDirection*: DriveDirection

type GameState* = ref object of RootObj
    level*: Level

    ## Input
    isThrottlePressed*: bool


    ## Physics
    space*: Space
    time*: Time
    finishFlipDirectionAt*: Option[Time]
    attitudeAdjustForce*: Float
    camera*: Camera
    driveDirection*: DriveDirection

    ## Player

    # bike bodies
    rearWheel*: Body
    frontWheel*: Body
    chassis*: Body
    swingArm*: Body
    forkArm*: Body
    bikeShapes*: seq[Shape]

    # rider bodies
    riderHead*: Body
    riderTorso*: Body
    riderUpperArm*: Body
    riderLowerArm*: Body
    riderUpperLeg*: Body
    riderLowerLeg*: Body
    # keep in sync with getRiderBodies()

    # Bike Constraints
    forkArmSpring*: DampedSpring
    bikeConstraints*: seq[Constraint]

    # Rider Constraints
    riderConstraints*: seq[Constraint] # todo remove if unused
    headRotarySpring*: DampedRotarySpring
    assPivot*: PivotJoint
    # shoulder to chassis
    shoulderPivot*: PivotJoint
    # upper arm to torso
    upperArmPivot*: PivotJoint
    elbowPivot*: PivotJoint
    hipPivot*: PivotJoint
    chassisKneePivot*: PivotJoint
    footPivot*: PivotJoint
    handPivot*: PivotJoint
    headPivot*: PivotJoint

    # Rider Shapes
    riderShapes*: seq[Shape]

proc getRiderBodies*(state: GameState): seq[Body] =
    result = @[
        state.riderHead,
        state.riderTorso,
        state.riderUpperArm,
        state.riderLowerArm,
        state.riderUpperLeg,
        state.riderLowerLeg,
    ]

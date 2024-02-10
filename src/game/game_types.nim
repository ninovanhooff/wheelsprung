import std/tables
import chipmunk7
import options
import graphics_types


type 
    Camera* = Vect
    DriveDirection* = Float

    Time* = float32
    Coin* = Vertex
    GameCollisionType* = CollisionType


const DD_LEFT*: DriveDirection = -1.0
const DD_RIGHT*: DriveDirection = 1.0

const GameCollisionTypes* = (
    None: cast[GameCollisionType](0), 
    Coin: cast[GameCollisionType](1), 
    Player: cast[GameCollisionType](2), # wheels and rider head
)

const PLAYER_MASK_BIT* = cuint(1 shl 31)
const TERRAIN_MASK_BIT* = cuint(1 shl 30)
const PLAYER_SHAPE_FILTER*: ShapeFilter =  ShapeFilter(
    categories: PLAYER_MASK_BIT,
    mask: TERRAIN_MASK_BIT
)

type Level* = ref object of RootObj
    groundPolygons*: seq[Polygon]
    coins*: seq[Coin]
    initialChassisPosition*: Vect
    initialDriveDirection*: DriveDirection

type GameState* = ref object of RootObj
    level*: Level

    remainingCoins*: seq[Coin]

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

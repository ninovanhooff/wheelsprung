import chipmunk7
import options
import graphics_types


type 
    Camera* = Vect
    DriveDirection* = Float

    Time* = float32
    Coin* = Vertex
    Killer* = Vertex
    Finish* = Vertex
    GameCollisionType* = CollisionType


const DD_LEFT*: DriveDirection = -1.0
const DD_RIGHT*: DriveDirection = 1.0

const GameCollisionTypes* = (
    None: cast[GameCollisionType](0), 
    Wheel: cast[GameCollisionType](1),
    Head: cast[GameCollisionType](2),
    Terrain: cast[GameCollisionType](3),
    Coin: cast[GameCollisionType](4), 
    Killer: cast[GameCollisionType](5),
    Finish: cast[GameCollisionType](6),
)

const TERRAIN_MASK_BIT = cuint(1 shl 30)
const COIN_MASK_BIT = cuint(1 shl 29)
const KILLER_MASK_BIT = cuint(1 shl 28)
const FINISH_MASK_BIT = cuint(1 shl 27)
const PLAYER_MASK_BIT = cuint(1 shl 26)

const GameShapeFilters* = (
    Player: ShapeFilter(
        categories: PLAYER_MASK_BIT,
        mask: TERRAIN_MASK_BIT or COIN_MASK_BIT or KILLER_MASK_BIT or FINISH_MASK_BIT
    ),
    Terrain: ShapeFilter(
        categories: TERRAIN_MASK_BIT,
        mask: PLAYER_MASK_BIT
    ),
    Coin: ShapeFilter(
        categories: COIN_MASK_BIT,
        mask: PLAYER_MASK_BIT
    ),
    Killer: ShapeFilter(
        categories: KILLER_MASK_BIT,
        mask: PLAYER_MASK_BIT
    ),
    Finish: ShapeFilter(
        categories: FINISH_MASK_BIT,
        mask: PLAYER_MASK_BIT
    ),
    # remember that collisions only happen when mask of both shapes match the category of the other
)

type Level* = ref object of RootObj
    terrainPolygons*: seq[Polygon]
    coins*: seq[Coin]
    killers*: seq[Killer]
    finishPosition*: Vertex
    cameraBounds*: BB
    initialChassisPosition*: Vect
    initialDriveDirection*: DriveDirection

type GameState* = ref object of RootObj
    level*: Level

    remainingCoins*: seq[Coin]
    killers*: seq[Body]

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

proc getRiderBodies*(state: GameState): seq[Body] =
    result = @[
        state.riderHead,
        state.riderTorso,
        state.riderUpperArm,
        state.riderLowerArm,
        state.riderUpperLeg,
        state.riderLowerLeg,
    ]
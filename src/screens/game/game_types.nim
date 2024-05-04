import playdate/api
import chipmunk7
import options
import common/graphics_types
import common/utils
import common/shared_types

type 
  Camera* = Vect
  DriveDirection* = Float
  RotationDirection* = DriveDirection

  Coin* = ref object
    position*: Vertex
    count*: int32
    activeFrom*: Seconds
  Star* = Vertex
  Killer* = Vertex
  Finish* = Vertex
  GravityZone* = ref object
    position*: Vertex
    gravity*: Vect
  GameCollisionType* = CollisionType

  RiderAttitudePosition* {.pure.} = enum
    Neutral, Forward, Backward



const DD_LEFT*: DriveDirection = -1.0
const DD_RIGHT*: DriveDirection = 1.0

const ROT_CCW*: RotationDirection = -1.0 # Counter Clockwise
const ROT_CW*: RotationDirection = 1.0 # Clockwise

const GameCollisionTypes* = (
  None: cast[GameCollisionType](0), 
  Wheel: cast[GameCollisionType](1),
  Head: cast[GameCollisionType](2),
  Terrain: cast[GameCollisionType](3),
  Coin: cast[GameCollisionType](4), 
  Killer: cast[GameCollisionType](5),
  Finish: cast[GameCollisionType](6),
  Chassis: cast[GameCollisionType](7),
  Star: cast[GameCollisionType](8),
  GravityZone: cast[GameCollisionType](9),
)

const TERRAIN_MASK_BIT = cuint(1 shl 30)
const COLLECTIBLE_MASK_BIT = cuint(1 shl 29)
const KILLER_MASK_BIT = cuint(1 shl 28)
const FINISH_MASK_BIT = cuint(1 shl 27)
const PLAYER_MASK_BIT = cuint(1 shl 26)
const GRAVITY_ZONE_MASK_BIT = cuint(1 shl 25)

const GameShapeFilters* = (
  Player: ShapeFilter(
    categories: PLAYER_MASK_BIT,
    mask: TERRAIN_MASK_BIT or COLLECTIBLE_MASK_BIT or KILLER_MASK_BIT or
      FINISH_MASK_BIT or GRAVITY_ZONE_MASK_BIT
  ),
  Terrain: ShapeFilter(
    categories: TERRAIN_MASK_BIT,
    mask: PLAYER_MASK_BIT
  ),
  Collectible: ShapeFilter(
    categories: COLLECTIBLE_MASK_BIT,
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
  GravityZone: ShapeFilter(
    categories: GRAVITY_ZONE_MASK_BIT,
    mask: PLAYER_MASK_BIT
  ),
  # WARNING Collisions only happen when mask of both shapes match the category of the other
)


type Direction8* = enum
  ## 4 horizontal and 4 diagonal directions
  D8_UP, D8_UP_RIGHT, D8_RIGHT, D8_DOWN_RIGHT, D8_DOWN, D8_DOWN_LEFT, D8_LEFT, D8_UP_LEFT

const D8_FALLBACK* = D8_UP

type Level* = ref object of RootObj
  id*: Path
  terrainPolygons*: seq[Polygon]
  terrainPolylines*: seq[Polyline]
  coins*: seq[Coin]
  killers*: seq[Killer]
  gravityZones*: seq[GravityZone]
  finishPosition*: Vertex
  finishRequiredRotations*: int32
  starPosition*: Option[Vertex]
  assets*: seq[Asset]
  ## Level size in Pixels
  size*: Size
  cameraBounds*: BB
  chassisBounds*: BB
  initialChassisPosition*: Vect
  initialDriveDirection*: DriveDirection

type AttitudeAdjust* = ref object
  # adjustType*: AttitudeAdjustType #todo move DpadInputType type def to proper place
  direction*: Float # 1.0 or -1.0, not necessarily the same as drive direction
  startedAt*: Seconds

type GameState* = ref object of RootObj
  level*: Level

  background*: LCDBitmap

  ## Game state
  isGameStarted*: bool
  remainingCoins*: seq[Coin]
  remainingStar*: Option[Star]
  killers*: seq[Body]
  gameResult*: Option[GameResult]

  ## Input
  isThrottlePressed*: bool
  isAccelerometerEnabled*: bool
  lastTorque*: Float # only used to display attitude indicator

  ## Navigation state
  resetGameOnResume*: bool

  ## time
  time*: Seconds
  frameCounter*: int32
  finishFlipDirectionAt*: Option[Seconds]
  finishTrophyBlinkerAt*: Option[Seconds]


  ## Physics
  space*: Space
  attitudeAdjust*: Option[AttitudeAdjust]
  camera*: Camera
  cameraOffset*: Vect
  driveDirection*: DriveDirection

  ## Player

  # bike bodies
  rearWheel*: Body
  frontWheel*: Body
  chassis*: Body
  swingArm*: Body
  forkArm*: Body

  # bike shapes
  bikeShapes*: seq[Shape]
  swingArmShape*: Shape
  forkArmShape*: Shape

  # Bike Constraints
  forkArmSpring*: DampedSpring
  bikeConstraints*: seq[Constraint]

  ## Rider
  riderAttitudePosition*: RiderAttitudePosition

  # rider bodies
  riderHead*: Body
  riderTorso*: Body
  riderUpperArm*: Body
  riderLowerArm*: Body
  riderUpperLeg*: Body
  riderLowerLeg*: Body
  # keep in sync with getRiderBodies()

  # Rider Constraints
  riderConstraints*: seq[Constraint] # todo remove if unused
  headRotarySpring*: DampedRotarySpring
  assPivot*: PivotJoint
  # shoulder to chassis
  shoulderPivot*: PivotJoint
  # upper arm to torso
  upperArmPivot*: PivotJoint
  elbowPivot*: PivotJoint
  elbowRotaryLimit*: RotaryLimitJoint
  hipPivot*: PivotJoint
  chassisKneePivot*: PivotJoint
  footPivot*: PivotJoint
  handPivot*: PivotJoint
  headPivot*: PivotJoint

proc newCoin*(position: Vertex, count: int32 = 1'i32): Coin =
  result = Coin(position: position, count: count)

proc newGravityZone*(position: Vertex, gravity: Vect): GravityZone =
  result = GravityZone(position: position, gravity: gravity)

proc getRiderBodies*(state: GameState): seq[Body] =
  result = @[
    state.riderHead,
    state.riderTorso,
    state.riderUpperArm,
    state.riderLowerArm,
    state.riderUpperLeg,
    state.riderLowerLeg,
  ]

proc destroy*(state: GameState) =
  print("Destroying game state")
  state.space.destroy()

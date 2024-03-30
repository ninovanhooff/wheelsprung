import chipmunk7
import options
import graphics_types
import utils
import shared_types
import playdate/api


type 
  Camera* = Vect
  DriveDirection* = Float

  Coin* = Vertex
  Star* = Vertex
  Killer* = Vertex
  Finish* = Vertex
  Texture* = object of RootObj
    image*: LCDBitmap
    position*: Vertex
    flip*: LCDBitmapFlip
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
  Chassis: cast[GameCollisionType](7),
  Star: cast[GameCollisionType](8),
)

const TERRAIN_MASK_BIT = cuint(1 shl 30)
const COLLECTIBLE_MASK_BIT = cuint(1 shl 29)
const KILLER_MASK_BIT = cuint(1 shl 28)
const FINISH_MASK_BIT = cuint(1 shl 27)
const PLAYER_MASK_BIT = cuint(1 shl 26)

const GameShapeFilters* = (
  Player: ShapeFilter(
    categories: PLAYER_MASK_BIT,
    mask: TERRAIN_MASK_BIT or COLLECTIBLE_MASK_BIT or KILLER_MASK_BIT or FINISH_MASK_BIT
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
  # remember that collisions only happen when mask of both shapes match the category of the other
)

type Level* = ref object of RootObj
  terrainPolygons*: seq[Polygon]
  coins*: seq[Coin]
  killers*: seq[Killer]
  finishPosition*: Vertex
  starPosition*: Option[Vertex]
  textures*: seq[Texture]
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

  ## timers
  finishFlipDirectionAt*: Option[Seconds]
  finishTrophyBlinkerAt*: Option[Seconds]


  ## Physics
  space*: Space
  time*: Seconds
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

proc destroy*(state: GameState) =
  print("Destroying game state")
  state.space.destroy()

proc newTexture*(image: LCDBitmap, position: Vertex, flip: LCDBitmapFlip): Texture =
  result = Texture(image: image, position: position, flip: flip)

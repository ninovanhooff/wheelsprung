import playdate/api
import chipmunk7
import options
import std/sugar
import std/sets
import common/graphics_types
import common/utils
import common/shared_types
import level_meta/level_data
import cache/bitmaptable_cache
import input/input_types
import game_constants
import pid_controller
export input_types
export game_constants

type 
  DriveDirection* = Float
  RotationDirection* = DriveDirection

  Direction8* = enum
    ## 4 horizontal and 4 diagonal directions
    D8_UP, D8_UP_RIGHT, D8_RIGHT, D8_DOWN_RIGHT, D8_DOWN, D8_DOWN_LEFT, D8_LEFT, D8_UP_LEFT

  Coin* = ref object
    position*: Vertex
    bounds*: LCDRect
    count*: int32
    coinIndex*: int32 ## index of the coin in the coin image table
    activeFrom*: Milliseconds
  Star* = Vertex
  Killer* = object
    bounds*: LCDRect
    body*: Body
  Finish* = object
    position*: Vertex
    bounds*: LCDRect
    flip*: LCDBitmapFlip
  GravityZone* = ref object
    position*: Vertex
    direction*: Direction8
    animation*: Animation
  GravityZoneSpec* = ref object
    position*: Vertex
    direction*: Direction8
  GameCollisionType* = CollisionType

  RiderAttitudePosition* {.pure.} = enum
    Neutral, Forward, Backward

  SizeF* = Vect

  Pose* = object
    position*: Vect
    angle*: Float

  PlayerPose* = object
    headPose*: Pose
    frontWheelPose*: Pose
    rearWheelPose*: Pose
    flipX*: bool

  Ghost* = ref object
    poses*: seq[PlayerPose]
    coinProgress*: float32
    gameResult*: GameResult

  DynamicObjectType* {.pure.} = enum 
    TallBook,
    TallPlank
    BowlingBall,
    Marble,
    TennisBall

  DynamicObject* = object
    shape*: Shape
    bitmapTable*: Option[AnnotatedBitmapTable]
    objectType*: Option[DynamicObjectType]

  DynamicBoxSpec* = object
    position*: Vect
    size*: Vect
    mass*: Float
    angle*: Float
    friction*: Float
    objectType*: Option[DynamicObjectType]

  DynamicCircleSpec* = object
    position*: Vect
    radius*: Float
    mass*: Float
    angle*: Float
    friction*: Float
    objectType*: Option[DynamicObjectType]


  Text* = object
    value*: string
    position*: Vertex
    alignment*: TextAlignment

const 
  GRAVITY_MAGNITUDE*: Float = 90.0

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
  DynamicObject: cast[GameCollisionType](10),
)

const TERRAIN_MASK_BIT = cuint(1 shl 30)
const COLLECTIBLE_MASK_BIT = cuint(1 shl 29)
const KILLER_MASK_BIT = cuint(1 shl 28)
const FINISH_MASK_BIT = cuint(1 shl 27)
const PLAYER_MASK_BIT = cuint(1 shl 26)
const GRAVITY_ZONE_MASK_BIT = cuint(1 shl 25)
const DYNAMIC_OBJECT_MASK_BIT = cuint(1 shl 24)

const GameShapeFilters* = (
  Player: ShapeFilter(
    categories: PLAYER_MASK_BIT,
    mask: TERRAIN_MASK_BIT or COLLECTIBLE_MASK_BIT or KILLER_MASK_BIT or
      FINISH_MASK_BIT or GRAVITY_ZONE_MASK_BIT or DYNAMIC_OBJECT_MASK_BIT
  ),
  Terrain: ShapeFilter(
    categories: TERRAIN_MASK_BIT,
    mask: PLAYER_MASK_BIT or DYNAMIC_OBJECT_MASK_BIT
  ),
  Collectible: ShapeFilter(
    categories: COLLECTIBLE_MASK_BIT,
    mask: PLAYER_MASK_BIT
  ),
  Killer: ShapeFilter(
    categories: KILLER_MASK_BIT,
    mask: PLAYER_MASK_BIT or DYNAMIC_OBJECT_MASK_BIT
  ),
  Finish: ShapeFilter(
    categories: FINISH_MASK_BIT,
    mask: PLAYER_MASK_BIT
  ),
  GravityZone: ShapeFilter(
    categories: GRAVITY_ZONE_MASK_BIT,
    mask: PLAYER_MASK_BIT
  ),
  DynamicObject: ShapeFilter(
    categories: DYNAMIC_OBJECT_MASK_BIT,
    mask: PLAYER_MASK_BIT or TERRAIN_MASK_BIT or KILLER_MASK_BIT or DYNAMIC_OBJECT_MASK_BIT
  ),
  # WARNING Collisions only happen when mask of both shapes match the category of the other
)

type Level* = ref object of RootObj
  id*: Path
  meta*: LevelMeta
  contentHash*: string
  background*: Option[LCDBitmap]
  hintsPath*: Option[Path]
  terrainPolygons*: seq[Polygon]
  terrainPolylines*: seq[Polyline]
  dynamicBoxes*: seq[DynamicBoxSpec]
  dynamicCircles*: seq[DynamicCircleSpec]
  coins*: seq[Coin]
  killers*: seq[Killer]
  gravityZones*: seq[GravityZoneSpec]
  texts*: seq[Text]
  finish*: Finish
  starPosition*: Option[Vertex]
  assets*: seq[Asset]
  ## Level size in Pixels
  size*: Size
  cameraBounds*: BB
  chassisBounds*: BB
  initialChassisPosition*: Vect
  initialDriveDirection*: DriveDirection

type AttitudeAdjust* = ref object
  direction*: Float # 1.0 or -1.0, not necessarily the same as drive direction
  startedAt*: Milliseconds

type GameStartState* = ref object of RootObj
  levelName*: string
  readyGoFrame*: int32
  gameStartFrame*: int32

type GameReplayState* = ref object of RootObj
  hideOverlayAt*: Option[Seconds]

type GameState* = ref object of RootObj
  level*: Level

  background*: LCDBitmap
  hintsEnabled*: bool

  # Game state
  isGameStarted*: bool
  isGamePaused*: bool
  remainingCoins*: seq[Coin]
  remainingStar*: Option[Star]
  starEnabled*: bool
    ## If the star is enabled, the player can collect it. Stars are enabled by finishing the level at least once.
  killers*: seq[Killer]
  gravityZones*: seq[GravityZone]
  gameResult*: Option[GameResult]

  # Input
  isThrottlePressed*: bool
  isAccelerometerEnabled*: bool
  lastTorque*: Float # torque applied by attitude adjust in last frame

  # Navigation state
  resetGameOnResume*: bool

  # time
  time*: Milliseconds
  gameStartState*: Option[GameStartState]
  gameReplayState*: Option[GameReplayState]
    ## Frame counter for the readyGo start animation
  frameCounter*: int32
  finishFlipDirectionAt*: Option[Milliseconds]
  finishTrophyBlinkerAt*: Option[Milliseconds]


  # Physics
  space*: Space
  gravityDirection*: Direction8
  attitudeAdjust*: Option[AttitudeAdjust]
  camera*: Camera
  cameraOffset*: Vect
  camXController*: PIDController
  camYController*: PIDController
  driveDirection*: DriveDirection
  dynamicObjects*: seq[DynamicObject]
  collidingShapes*: sets.HashSet[Shape]

  ## Ghost
  ghostRecording*: Ghost
    ## A ghost that is being recorded
  ghostPlayback*: Ghost
    ## A ghost that represents the best time for the level
  
  inputRecording*: InputRecording
  inputProvider*: InputProvider

  # Player
  # bike bodies
  rearWheel*: Body
  frontWheel*: Body
  chassis*: Body
  swingArm*: Body
  forkArm*: Body

  # bike shapes
  bikeShapes*: seq[Shape]
  chassisShape*: Shape
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
  riderTail*: Body
  riderUpperArm*: Body
  riderLowerArm*: Body
  riderUpperLeg*: Body
  riderLowerLeg*: Body
  # keep in sync with getRiderBodies()

  # Rider Constraints
  riderConstraints*: seq[Constraint] # todo remove if unused
  headRotarySpring*: DampedRotarySpring
  tailRotarySpring*: DampedRotarySpring
  assPivot*: PivotJoint
  # tail to chassis
  tailPivot*: PivotJoint
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

proc newFinish*(position: Vertex, flip: LCDBitmapFlip): Finish =
  result = Finish(
    position: position,
    bounds: LCDRect(
      left: position.x, 
      right: position.x + finishSize,
      top: position.y,
      bottom: position.y + finishSize,
    ),
    flip: flip
  )

proc newCoin*(position: Vertex, count: int32 = 1, coinIndex: int32 = 0): Coin =
  result = Coin(
    position: position,
    bounds: LCDRect(
      left: position.x, 
      right: position.x + coinSize,
      top: position.y,
      bottom: position.y + coinSize,
    ),
    count: count,
    coinIndex: coinIndex,
  )

proc newKiller*(position: Vertex): Killer =
  result = Killer(
    bounds: LCDRect(
      left: position.x, 
      right: position.x + killerSize,
      top: position.y,
      bottom: position.y + killerSize,
    )
  )

proc newKiller*(bounds: LCDRect, body: Body): Killer =
  result = Killer(bounds: bounds, body: body)

proc newGravityZone*(position: Vertex, direction: Direction8, animation: Animation): GravityZone =
  result = GravityZone(position: position, direction: direction, animation: animation)

proc newGravityZoneSpec*(position: Vertex, direction: Direction8): GravityZoneSpec =
  result = GravityZoneSpec(position: position, direction: direction)

proc toBitmapTableId*(objectType: DynamicObjectType): BitmapTableId =
  case objectType
  of DynamicObjectType.TallBook: BitmapTableId.TallBook
  of DynamicObjectType.TallPlank: BitmapTableId.TallPlank
  of DynamicObjectType.BowlingBall: BitmapTableId.BowlingBall
  of DynamicObjectType.Marble: BitmapTableId.Marble
  of DynamicObjectType.TennisBall: BitmapTableId.TennisBall

proc newDynamicObject*(shape: Shape, objectType: Option[DynamicObjectType] = none(DynamicObjectType)): DynamicObject =
  let bitmapTableId = objectType.map(it => it.toBitmapTableId())
  let bitmapTable = bitmapTableId.map(it => getOrLoadBitmapTable(it))
  result = DynamicObject(
    shape: shape, 
    bitmapTable: bitmapTable,
    objectType: objectType
  )

proc newDynamicBoxSpec*(position: Vect, size: Vect, mass: Float, angle: Float, friction: Float, objectType: Option[DynamicObjectType]): DynamicBoxSpec =
  if mass <= 0.0:
    raise newException(RangeDefect, "Box mass must be greater than 0")
  result = DynamicBoxSpec(position: position, size: size, mass: mass, angle: angle, friction: friction, objectType: objectType)

proc newDynamicCircleSpec*(position: Vect, radius: Float, mass: Float, angle: Float, friction: Float, objectType: Option[DynamicObjectType]): DynamicCircleSpec =
  if mass <= 0.0:
    raise newException(RangeDefect, "Circle mass must be greater than 0")
  result = DynamicCircleSpec(position: position, radius: radius, mass: mass, angle: angle, friction: friction, objectType: objectType)

proc newText*(value: string, position: Vertex, alignment: TextAlignment): Text =
  result = Text(
    value: value,
    position: position,
    alignment: alignment,
  )

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
  if state != nil and state.space != nil:
    state.collidingShapes.clear()
    state.space.destroy()
    state.space = nil

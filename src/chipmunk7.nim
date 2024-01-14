# Copyright (C) 2015 Oleh Prypin <blaxpirit@gmail.com>
# Licensed under terms of MIT license (see LICENSE)

{.deadCodeElim: on.}
{.warning[SmallLshouldNotBeUsed]: off.}

when defined chipmunkDestructors:
  # Destroy is called automatically, based on scope
  {.experimental.}
  {.pragma: destroy, override.}
else:
  # Call destroy() manually, beware of memory leaks!
  {.pragma: destroy.}

import math

converter toBool[T](x: ptr T): bool = x != nil

type
  Float* = cfloat
    ## Chipmunk's floating point type.

proc `div`(x, y: Float): Float = x / y


type
  HashValue* = pointer
    ## Hash value type.

  CollisionID* = uint32
    ## Type used internally to cache colliding object info for cpCollideShapes().
    ## Should be at least 32 bits.

  DataPointer* = pointer
    ## Type used for user data pointers.

  CollisionType* = pointer
    ## Type used for cpSpace.collision_type.

  Group* = pointer
    ## Type used for cpShape.group.

  Bitmask* = cuint
    ## Type used for cpShapeFilter category and mask.

  Timestamp* = cuint
    ## Type used for various timestamps in Chipmunk.

  Vect* {.bycopy.} = object
    ## Chipmunk's 2D vector type.
    x*: Float
    y*: Float

  Transform* {.bycopy.} = object
    ## Column major affine transform.
    a*: Float
    b*: Float
    c*: Float
    d*: Float
    tx*: Float
    ty*: Float

  Mat2x2* {.bycopy.} = object
    a*: Float
    b*: Float
    c*: Float
    d*: Float

  Array* = ptr object

  HashSet* = ptr object

  Body* = ptr object

  ShapeType* {.bycopy.} = enum
    cpCircleShape = 0, cpSegmentShape = 1, cpPolyShape = 2
  ShapeObj {.inheritable.} = object
  Shape* = ptr ShapeObj

  CircleShape* = ptr object of Shape

  SegmentShape* = ptr object of Shape

  PolyShape* = ptr object of Shape

  ConstraintObj {.inheritable.} = object
  Constraint* = ptr ConstraintObj

  PinJoint* = ptr object of Constraint

  SlideJoint* = ptr object of Constraint

  PivotJoint* = ptr object of Constraint

  GrooveJoint* = ptr object of Constraint

  DampedSpring* = ptr object of Constraint

  DampedRotarySpring* = ptr object of Constraint

  RotaryLimitJoint* = ptr object of Constraint

  RatchetJoint* = ptr object of Constraint

  GearJoint* = ptr object of Constraint

  SimpleMotorJoint* = ptr object

  Arbiter* = ptr object

  Space* = ptr object

  BB* {.bycopy.} = object
    ## Chipmunk's axis-aligned 2D bounding box type. (left, bottom, right, top)
    l*: Float
    b*: Float
    r*: Float
    t*: Float

  SpatialIndexBBFunc* = proc (obj: pointer): BB {.cdecl.}
    ## Spatial index bounding box callback function type.
    ## The spatial index calls this function and passes you a pointer to an object you added
    ## when it needs to get the bounding box associated with that object.

  SpatialIndexIteratorFunc* = proc (obj: pointer; data: pointer) {.cdecl.}
    ## Spatial index/object iterator callback function type.

  SpatialIndexQueryFunc* = proc (obj1: pointer; obj2: pointer; id: CollisionID; data: pointer): CollisionID {.cdecl.}
    ## Spatial query callback function type.

  SpatialIndexSegmentQueryFunc* = proc (obj1: pointer; obj2: pointer; data: pointer): Float {.cdecl.}
    ## Spatial segment query callback function type.

  SpatialIndexObj {.inheritable.} = object
    klass*: ptr SpatialIndexClass
    bbfunc*: SpatialIndexBBFunc
    staticIndex*: SpatialIndex
    dynamicIndex*: SpatialIndex
  SpatialIndex* = ptr SpatialIndexObj

  SpaceHash* = ptr object of SpatialIndex

  BBTree* = ptr object of SpatialIndex

  BBTreeVelocityFunc* = proc (obj: pointer): Vect {.cdecl.}
    ## Bounding box tree velocity callback function.
    ## This function should return an estimate for the object's velocity.


  Sweep1D* = ptr object of SpatialIndex

  SpatialIndexDestroyImpl* = proc (index: SpatialIndex) {.cdecl.}

  SpatialIndexCountImpl* = proc (index: SpatialIndex): cint {.cdecl.}

  SpatialIndexEachImpl* = proc (index: SpatialIndex; `func`: SpatialIndexIteratorFunc; data: pointer) {.cdecl.}

  SpatialIndexContainsImpl* = proc (index: SpatialIndex; obj: pointer; hashid: HashValue): bool {.cdecl.}

  SpatialIndexInsertImpl* = proc (index: SpatialIndex; obj: pointer; hashid: HashValue) {.cdecl.}

  SpatialIndexRemoveImpl* = proc (index: SpatialIndex; obj: pointer; hashid: HashValue) {.cdecl.}

  SpatialIndexReindexImpl* = proc (index: SpatialIndex) {.cdecl.}

  SpatialIndexReindexObjectImpl* = proc (index: SpatialIndex; obj: pointer; hashid: HashValue) {.cdecl.}

  SpatialIndexReindexQueryImpl* = proc (index: SpatialIndex; `func`: SpatialIndexQueryFunc; data: pointer) {.cdecl.}

  SpatialIndexQueryImpl* = proc (index: SpatialIndex; obj: pointer; bb: BB; `func`: SpatialIndexQueryFunc; data: pointer) {.cdecl.}

  SpatialIndexSegmentQueryImpl* = proc (index: SpatialIndex; obj: pointer; a: Vect; b: Vect; t_exit: Float; `func`: SpatialIndexSegmentQueryFunc; data: pointer) {.cdecl.}

  SpatialIndexClass* {.bycopy.} = object
    destroy*: SpatialIndexDestroyImpl
    count*: SpatialIndexCountImpl
    each*: SpatialIndexEachImpl
    contains*: SpatialIndexContainsImpl
    insert*: SpatialIndexInsertImpl
    remove*: SpatialIndexRemoveImpl
    reindex*: SpatialIndexReindexImpl
    reindexObject*: SpatialIndexReindexObjectImpl
    reindexQuery*: SpatialIndexReindexQueryImpl
    query*: SpatialIndexQueryImpl
    segmentQuery*: SpatialIndexSegmentQueryImpl

  ContactPoint* {.bycopy.} = object
    ## Used in ContactPointSet
    pointA*: Vect
    pointB*: Vect
      ## The position of the contact on the surface of each shape.
    distance*: Float
      ## Penetration distance of the two shapes. Overlapping means it will be negative.
      ## This value is calculated as cpvdot(cpvsub(point2, point1), normal) and is ignored by cpArbiterSetContactPointSet().


  ContactPointSet* {.bycopy.} = object
    ## A struct that wraps up the important collision data for an arbiter.
    count*: cint
      ## The number of contact points in the set.
    normal*: Vect
      ## The normal of the collision.
    points*: array[2, ContactPoint]
      ## The array of contact points.

  BodyType* {.size: sizeof(cint).} = enum
    BODY_TYPE_DYNAMIC,
      ## A dynamic body is one that is affected by gravity, forces, and collisions.
      ## This is the default body type.
    BODY_TYPE_KINEMATIC,
      ## A kinematic body is an infinite mass, user controlled body that is not affected by gravity, forces or collisions.
      ## Instead the body only moves based on it's velocity.
      ## Dynamic bodies collide normally with kinematic bodies, though the kinematic body will be unaffected.
      ## Collisions between two kinematic bodies, or a kinematic body and a static body produce collision callbacks, but no collision response.
    BODY_TYPE_STATIC
      ## A static body is a body that never (or rarely) moves. If you move a static body, you must call one of the cpSpaceReindex*() functions.
      ## Chipmunk uses this information to optimize the collision detection.
      ## Static bodies do not produce collision callbacks when colliding with other static bodies.

  BodyVelocityFunc* = proc (body: Body; gravity: Vect; damping: Float; dt: Float) {.cdecl.}
    ## Rigid body velocity update function type.

  BodyPositionFunc* = proc (body: Body; dt: Float) {.cdecl.}
    ## Rigid body position update function type.

  BodyShapeIteratorFunc* = proc (body: Body; shape: Shape; data: pointer) {.cdecl.}
    ## Call `func` once for each shape attached to `body` and added to the space.

  BodyConstraintIteratorFunc* = proc (body: Body; constraint: Constraint; data: pointer) {.cdecl.}
    ## Body/constraint iterator callback function type.

  BodyArbiterIteratorFunc = proc (body: Body; arbiter: Arbiter; data: pointer) {.cdecl.}
    ## Body/arbiter iterator callback function type.

  PointQueryInfo* {.bycopy.} = object
    ## Point query info struct.
    shape*: Shape
      ## The nearest shape, NULL if no shape was within range.
    point*: Vect
      ## The closest point on the shape's surface. (in world space coordinates)
    distance*: Float
      ## The distance to the point. The distance is negative if the point is inside the shape.
    gradient*: Vect
      ## The gradient of the signed distance function.
      ## The value should be similar to info.p/info.d, but accurate even for very small values of info.d.

  SegmentQueryInfo* {.bycopy.} = object
    ## Segment query info struct.
    shape*: Shape
      ## The shape that was hit, or NULL if no collision occured.
    point*: Vect
      ## The point of impact.
    normal*: Vect
      ## The normal of the surface hit.
    alpha*: Float
      ## The normalized distance along the query segment in the range [0, 1].

  ShapeFilter* {.bycopy.} = object
    ## Fast collision filtering type that is used to determine if two objects collide before calling collision or query callbacks.
    group*: Group
      ## Two objects with the same non-zero group value do not collide.
      ## This is generally used to group objects in a composite object together to disable self collisions.
    categories*: Bitmask
      ## A bitmask of user definable categories that this object belongs to.
      ## The category/mask combinations of both objects in a collision must agree for a collision to occur.
    mask*: Bitmask
      ## A bitmask of user definable category types that this object object collides with.
      ## The category/mask combinations of both objects in a collision must agree for a collision to occur.

  ConstraintPreSolveFunc* = proc (constraint: Constraint; space: Space) {.cdecl.}
    ## Callback function type that gets called before solving a joint.

  ConstraintPostSolveFunc* = proc (constraint: Constraint; space: Space) {.cdecl.}
    ## Callback function type that gets called after solving a joint.

  DampedSpringForceFunc* = proc (spring: Constraint; dist: Float): Float {.cdecl.}
    ## Function type used for damped spring force callbacks.

  DampedRotarySpringTorqueFunc* = proc (spring: Constraint; relativeAngle: Float): Float {.cdecl.}
    ## Function type used for damped rotary spring force callbacks.

  SimpleMotor* = ptr object of Constraint
    ## Opaque struct type for damped rotary springs.

  CollisionBeginFunc* = proc (arb: Arbiter; space: Space; userData: DataPointer): bool {.cdecl.}
    ## Collision begin event function callback type.
    ## Returning false from a begin callback causes the collision to be ignored until
    ## the the separate callback is called when the objects stop colliding.

  CollisionPreSolveFunc* = proc (arb: Arbiter; space: Space; userData: DataPointer): bool {.cdecl.}
    ## Collision pre-solve event function callback type.
    ## Returning false from a pre-step callback causes the collision to be ignored until the next step.

  CollisionPostSolveFunc* = proc (arb: Arbiter; space: Space; userData: DataPointer) {.cdecl.}
    ## Collision post-solve event function callback type.

  CollisionSeparateFunc* = proc (arb: Arbiter; space: Space; userData: DataPointer) {.cdecl.}
    ## Collision separate event function callback type.

  CollisionHandler* {.bycopy.} = object
    ## Struct that holds function callback pointers to configure custom collision handling.
    ## Collision handlers have a pair of types; when a collision occurs between two shapes that have these types, the collision handler functions are triggered.
    typeA*: CollisionType
      ## Collision type identifier of the first shape that this handler recognizes.
      ## In the collision handler callback, the shape with this type will be the first argument. Read only.
    typeB*: CollisionType
      ## Collision type identifier of the second shape that this handler recognizes.
      ## In the collision handler callback, the shape with this type will be the second argument. Read only.
    beginFunc*: CollisionBeginFunc
      ## This function is called when two shapes with types that match this collision handler begin colliding.
    preSolveFunc*: CollisionPreSolveFunc
      ## This function is called each step when two shapes with types that match this collision handler are colliding.
      ## It's called before the collision solver runs so that you can affect a collision's outcome.
    postSolveFunc*: CollisionPostSolveFunc
      ## This function is called each step when two shapes with types that match this collision handler are colliding.
      ## It's called after the collision solver runs so that you can read back information about the collision to trigger events in your game.
    separateFunc*: CollisionSeparateFunc
      ## This function is called when two shapes with types that match this collision handler stop colliding.
    userData*: DataPointer
      ## This is a user definable context pointer that is passed to all of the collision handler functions.

  PostStepFunc* = proc (space: Space; key: pointer; data: pointer) {.cdecl.}
    ## Post Step callback function type.

  SpacePointQueryFunc* = proc (shape: Shape; point: Vect; distance: Float; gradient: Vect; data: pointer) {.cdecl.}
    ## Nearest point query callback function type.

  SpaceSegmentQueryFunc* = proc (shape: Shape; point: Vect; normal: Vect; alpha: Float; data: pointer) {.cdecl.}
    ## Segment query callback function type.

  SpaceBBQueryFunc* = proc (shape: Shape; data: pointer) {.cdecl.}
    ## Rectangle Query callback function type.

  SpaceShapeQueryFunc* = proc (shape: Shape; points: ptr ContactPointSet; data: pointer) {.cdecl.}
    ## Shape query callback function type.

  SpaceBodyIteratorFunc* = proc (body: Body; data: pointer) {.cdecl.}
    ## Space/body iterator callback function type.

  SpaceShapeIteratorFunc* = proc (shape: Shape; data: pointer) {.cdecl.}
    ## Space/body iterator callback function type.

  SpaceConstraintIteratorFunc* = proc (constraint: Constraint; data: pointer) {.cdecl.}
    ## Space/constraint iterator callback function type.

  SpaceDebugColor* {.bycopy.} = object
    ## Color type to use with the space debug drawing API.
    r*: cfloat
    g*: cfloat
    b*: cfloat
    a*: cfloat

  SpaceDebugDrawCircleImpl* = proc (pos: Vect; angle: Float; radius: Float; outlineColor: SpaceDebugColor; fillColor: SpaceDebugColor; data: DataPointer) {.cdecl.}
    ## Callback type for a function that draws a filled, stroked circle.

  SpaceDebugDrawSegmentImpl* = proc (a: Vect; b: Vect; color: SpaceDebugColor; data: DataPointer) {.cdecl.}
    ## Callback type for a function that draws a line segment.

  SpaceDebugDrawFatSegmentImpl* = proc (a: Vect; b: Vect; radius: Float; outlineColor: SpaceDebugColor; fillColor: SpaceDebugColor; data: DataPointer) {.cdecl.}
    ## Callback type for a function that draws a thick line segment.

  SpaceDebugDrawPolygonImpl* = proc (count: cint; verts: ptr Vect; radius: Float; outlineColor: SpaceDebugColor; fillColor: SpaceDebugColor; data: DataPointer) {.cdecl.}
    ## Callback type for a function that draws a convex polygon.

  SpaceDebugDrawDotImpl* = proc (size: Float; pos: Vect; color: SpaceDebugColor; data: DataPointer) {.cdecl.}
    ## Callback type for a function that draws a dot.

  SpaceDebugDrawColorForShapeImpl* = proc (shape: Shape; data: DataPointer): SpaceDebugColor {.cdecl.}
    ## Callback type for a function that returns a color for a given shape. This gives you an opportunity to color shapes based on how they are used in your engine.

  SpaceDebugDrawFlags* {.size: sizeof(cint).} = enum
    SPACE_DEBUG_DRAW_SHAPES = 1 shl 0,
    SPACE_DEBUG_DRAW_CONSTRAINTS = 1 shl 1,
    SPACE_DEBUG_DRAW_COLLISION_POINTS = 1 shl 2

  SpaceDebugDrawOptions* {.bycopy.} = object
    ## Struct used with cpSpaceDebugDraw() containing drawing callbacks and other drawing settings.
    drawCircle*: SpaceDebugDrawCircleImpl
      ## Function that will be invoked to draw circles.
    drawSegment*: SpaceDebugDrawSegmentImpl
      ## Function that will be invoked to draw line segments.
    drawFatSegment*: SpaceDebugDrawFatSegmentImpl
      ## Function that will be invoked to draw thick line segments.
    drawPolygon*: SpaceDebugDrawPolygonImpl
      ## Function that will be invoked to draw convex polygons.
    drawDot*: SpaceDebugDrawDotImpl
      ## Function that will be invoked to draw dots.
    flags*: SpaceDebugDrawFlags
      ## Flags that request which things to draw (collision shapes, constraints, contact points).
    shapeOutlineColor*: SpaceDebugColor
      ## Outline color passed to the drawing function.
    colorForShape*: SpaceDebugDrawColorForShapeImpl
      ## Function that decides what fill color to draw shapes using.
    constraintColor*: SpaceDebugColor
      ## Color passed to drawing functions for constraints.
    collisionPointColor*: SpaceDebugColor
      ## Color passed to drawing functions for collision points.
    data*: DataPointer
      ## User defined context pointer passed to all of the callback functions as the 'data' argument.


proc message*(condition: cstring; file: cstring; line: cint; isError: cint; isHardError: cint; message: cstring) {.varargs, cdecl, importc: "cpMessage".}


proc fmax*(a: Float; b: Float): Float {.inline, cdecl.} =
  ## Return the max of two cpFloats
  return if (a > b): a else: b


proc fmin*(a: Float; b: Float): Float {.inline, cdecl.} =
  ## Return the min of two cpFloats
  return if (a < b): a else: b


proc fabs*(f: Float): Float {.inline, cdecl.} =
  ## Return the absolute value of a cpFloat.
  return if (f < 0): - f else: f


proc fclamp*(f: Float; min: Float; max: Float): Float {.inline, cdecl.} =
  ## Clamp `f` to be between `min` and `max`.
  return fmin(fmax(f, min), max)


proc fclamp01*(f: Float): Float {.inline, cdecl.} =
  ## Clamp `f` to be between 0 and 1.
  return fmax(0.0, fmin(f, 1.0))


proc flerp*(f1: Float; f2: Float; t: Float): Float {.inline, cdecl.} =
  ## Linearly interpolate (or extrapolate) between `f1` and `f2` by `t` percent.
  return f1 * (1.0 - t) + f2 * t


proc flerpconst*(f1: Float; f2: Float; d: Float): Float {.inline, cdecl.} =
  ## Linearly interpolate from `f1` to `f2` by no more than `d`.
  return f1 + fclamp(f2 - f1, - d, d)



var vzero* = Vect(x: 0.0, y: 0.0)
  ## Constant for the zero vector.


proc v*(x: Float; y: Float): Vect {.inline, cdecl.} =
  ## Convenience constructor for cpVect structs.
  var v = Vect(x: x, y: y)
  return v


proc veql*(v1: Vect; v2: Vect): bool {.inline, cdecl.} =
  ## Check if two vectors are equal. (Be careful when comparing floating point numbers!)
  return v1.x == v2.x and v1.y == v2.y


proc vadd*(v1: Vect; v2: Vect): Vect {.inline, cdecl.} =
  ## Add two vectors
  return v(v1.x + v2.x, v1.y + v2.y)


proc vsub*(v1: Vect; v2: Vect): Vect {.inline, cdecl.} =
  ## Subtract two vectors.
  return v(v1.x - v2.x, v1.y - v2.y)


proc vneg*(v: Vect): Vect {.inline, cdecl.} =
  ## Negate a vector.
  return v(- v.x, - v.y)


proc vmult*(v: Vect; s: Float): Vect {.inline, cdecl.} =
  ## Scalar multiplication.
  return v(v.x * s, v.y * s)


proc vdot*(v1: Vect; v2: Vect): Float {.inline, cdecl.} =
  ## Vector dot product.
  return v1.x * v2.x + v1.y * v2.y


proc vcross*(v1: Vect; v2: Vect): Float {.inline, cdecl.} =
  ## 2D vector cross product analog.
  ## The cross product of 2D vectors results in a 3D vector with only a z component.
  ## This function returns the magnitude of the z value.
  return v1.x * v2.y - v1.y * v2.x


proc vperp*(v: Vect): Vect {.inline, cdecl.} =
  ## Returns a perpendicular vector. (90 degree rotation)
  return v(- v.y, v.x)


proc vrperp*(v: Vect): Vect {.inline, cdecl.} =
  ## Returns a perpendicular vector. (-90 degree rotation)
  return v(v.y, - v.x)


proc vproject*(v1: Vect; v2: Vect): Vect {.inline, cdecl.} =
  ## Returns the vector projection of v1 onto v2.
  return vmult(v2, vdot(v1, v2) div vdot(v2, v2))


proc vforangle*(a: Float): Vect {.inline, cdecl.} =
  ## Returns the unit length vector for the given angle (in radians).
  return v(cos(a), sin(a))


proc vtoangle*(v: Vect): Float {.inline, cdecl.} =
  ## Returns the angular direction v is pointing in (in radians).
  return arctan2(v.y, v.x)


proc vrotate*(v1: Vect; v2: Vect): Vect {.inline, cdecl.} =
  ## Uses complex number multiplication to rotate v1 by v2. Scaling will occur if v1 is not a unit vector.
  return v(v1.x * v2.x - v1.y * v2.y, v1.x * v2.y + v1.y * v2.x)


proc vunrotate*(v1: Vect; v2: Vect): Vect {.inline, cdecl.} =
  ## Inverse of cpvrotate().
  return v(v1.x * v2.x + v1.y * v2.y, v1.y * v2.x - v1.x * v2.y)


proc vlengthsq*(v: Vect): Float {.inline, cdecl.} =
  ## Returns the squared length of v. Faster than cpvlength() when you only need to compare lengths.
  return vdot(v, v)


proc vlength*(v: Vect): Float {.inline, cdecl.} =
  ## Returns the length of v.
  return sqrt(vdot(v, v))


proc vlerp*(v1: Vect; v2: Vect; t: Float): Vect {.inline, cdecl.} =
  ## Linearly interpolate between v1 and v2.
  return vadd(vmult(v1, 1.0 - t), vmult(v2, t))


proc vnormalize*(v: Vect): Vect {.inline, cdecl.} =
  ## Returns a normalized copy of v.
  return vmult(v, 1.0 div
      (vlength(v) + (cast[Float](2.225073858507201e-308))))


proc vslerp*(v1: Vect; v2: Vect; t: Float): Vect {.inline, cdecl.} =
  ## Spherical linearly interpolate between v1 and v2.
  var dot: Float = vdot(vnormalize(v1), vnormalize(v2))
  var omega: Float = arccos(fclamp(dot, - 1.0, 1.0))
  if omega < 1e-3:
    return vlerp(v1, v2, t)
  else:
    var denom: Float = 1.0 div sin(omega)
    return vadd(vmult(v1, sin((1.0 - t) * omega) * denom),
                  vmult(v2, sin(t * omega) * denom))


proc vslerpconst*(v1: Vect; v2: Vect; a: Float): Vect {.inline, cdecl.} =
  ## Spherical linearly interpolate between v1 towards v2 by no more than angle a radians
  var dot: Float = vdot(vnormalize(v1), vnormalize(v2))
  var omega: Float = arccos(fclamp(dot, - 1.0, 1.0))
  return vslerp(v1, v2, fmin(a, omega) div omega)


proc vclamp*(v: Vect; len: Float): Vect {.inline, cdecl.} =
  ## Clamp v to length len.
  return if (vdot(v, v) > len * len): vmult(vnormalize(v), len) else: v


proc vlerpconst*(v1: Vect; v2: Vect; d: Float): Vect {.inline, cdecl.} =
  ## Linearly interpolate between v1 towards v2 by distance d.
  return vadd(v1, vclamp(vsub(v2, v1), d))


proc vdist*(v1: Vect; v2: Vect): Float {.inline, cdecl.} =
  ## Returns the distance between v1 and v2.
  return vlength(vsub(v1, v2))


proc vdistsq*(v1: Vect; v2: Vect): Float {.inline, cdecl.} =
  ## Returns the squared distance between v1 and v2. Faster than cpvdist() when you only need to compare distances.
  return vlengthsq(vsub(v1, v2))


proc vnear*(v1: Vect; v2: Vect; dist: Float): bool {.inline, cdecl.} =
  ## Returns true if the distance between v1 and v2 is less than dist.
  return vdistsq(v1, v2) < dist * dist

proc newMat2x2*(a: Float; b: Float; c: Float; d: Float): Mat2x2 {.inline, cdecl.} =
  var m = Mat2x2(a: a, b: b, c: c, d: d)
  return m

proc transform*(m: Mat2x2; v: Vect): Vect {.inline, cdecl.} =
  #"cpMat2x2Transform"
  return v(v.x * m.a + v.y * m.b, v.x * m.c + v.y * m.d)



proc newBB*(l: Float; b: Float; r: Float; t: Float): BB {.inline, cdecl.} =
  ## Convenience constructor for cpBB structs.
  var bb = BB(l: l, b: b, r: r, t: t)
  return bb


proc newForExtentsBB*(c: Vect; hw: Float; hh: Float): BB {.inline, cdecl.} =
  ## Constructs a cpBB centered on a point with the given extents (half sizes).
  return newBB(c.x - hw, c.y - hh, c.x + hw, c.y + hh)


proc newForCircleBB*(p: Vect; r: Float): BB {.inline, cdecl.} =
  ## Constructs a cpBB for a circle with the given position and radius.
  return newForExtentsBB(p, r, r)


proc intersects*(a: BB; b: BB): bool {.inline, cdecl.} =
  ## Returns true if `a` and `b` intersect.
  return a.l <= b.r and b.l <= a.r and a.b <= b.t and b.b <= a.t


proc containsBB*(bb: BB; other: BB): bool {.inline, cdecl.} =
  ## Returns true if `other` lies completely within `bb`.
  return bb.l <= other.l and bb.r >= other.r and bb.b <= other.b and
      bb.t >= other.t


proc containsVect*(bb: BB; v: Vect): bool {.inline, cdecl.} =
  ## Returns true if `bb` contains `v`.
  return bb.l <= v.x and bb.r >= v.x and bb.b <= v.y and bb.t >= v.y


proc merge*(a: BB; b: BB): BB {.inline, cdecl.} =
  ## Returns a bounding box that holds both bounding boxes.
  return newBB(fmin(a.l, b.l), fmin(a.b, b.b), fmax(a.r, b.r),
      fmax(a.t, b.t))


proc expand*(bb: BB; v: Vect): BB {.inline, cdecl.} =
  ## Returns a bounding box that holds both `bb` and `v`.
  return newBB(fmin(bb.l, v.x), fmin(bb.b, v.y), fmax(bb.r, v.x),
      fmax(bb.t, v.y))


proc center*(bb: BB): Vect {.inline, cdecl.} =
  ## Returns the center of a bounding box.
  return vlerp(v(bb.l, bb.b), v(bb.r, bb.t), 0.5)


proc area*(bb: BB): Float {.inline, cdecl.} =
  ## Returns the area of the bounding box.
  return (bb.r - bb.l) * (bb.t - bb.b)


proc mergedArea*(a: BB; b: BB): Float {.inline, cdecl.} =
  ## Merges `a` and `b` and returns the area of the merged bounding box.
  return (fmax(a.r, b.r) - fmin(a.l, b.l)) *
      (fmax(a.t, b.t) - fmin(a.b, b.b))


proc segmentQuery*(bb: BB; a: Vect; b: Vect): Float {.inline, cdecl.} =
  ## Returns the fraction along the segment query the cpBB is hit. Returns INFINITY if it doesn't hit.
  var idx: Float = 1.0 div (b.x - a.x)
  var tx1: Float = (if bb.l == a.x: - (Inf) else: (bb.l - a.x) * idx)
  var tx2: Float = (if bb.r == a.x: (Inf) else: (bb.r - a.x) * idx)
  var txmin: Float = fmin(tx1, tx2)
  var txmax: Float = fmax(tx1, tx2)
  var idy: Float = 1.0 div (b.y - a.y)
  var ty1: Float = (if bb.b == a.y: - (Inf) else: (bb.b - a.y) * idy)
  var ty2: Float = (if bb.t == a.y: (Inf) else: (bb.t - a.y) * idy)
  var tymin: Float = fmin(ty1, ty2)
  var tymax: Float = fmax(ty1, ty2)
  if tymin <= txmax and txmin <= tymax:
    var min: Float = fmax(txmin, tymin)
    var max: Float = fmin(txmax, tymax)
    if 0.0 <= max and min <= 1.0: return fmax(min, 0.0)
  return Inf


proc intersectsSegment*(bb: BB; a: Vect; b: Vect): bool {.inline, cdecl.} =
  ## Return true if the bounding box intersects the line segment with ends `a` and `b`.
  return segmentQuery(bb, a, b) != (Inf)


proc clampVect*(bb: BB; v: Vect): Vect {.inline, cdecl.} =
  ## Clamp a vector to a bounding box.
  return v(fclamp(v.x, bb.l, bb.r), fclamp(v.y, bb.b, bb.t))


proc wrapVect*(bb: BB; v: Vect): Vect {.inline, cdecl.} =
  ## Wrap a vector to a bounding box.
  var dx: Float = fabs(bb.r - bb.l)
  var modx: Float = (v.x - bb.l) mod dx
  var x: Float = if (modx > 0.0): modx else: modx + dx
  var dy: Float = fabs(bb.t - bb.b)
  var mody: Float = (v.y - bb.b) mod dy
  var y: Float = if (mody > 0.0): mody else: mody + dy
  return v(x + bb.l, y + bb.b)


proc offset*(bb: BB; v: Vect): BB {.inline, cdecl.} =
  ## Returns a bounding box offseted by `v`.
  return newBB(bb.l + v.x, bb.b + v.y, bb.r + v.x, bb.t + v.y)


var TransformIdentity* = Transform(a: 1.0, b: 0.0, c: 0.0, d: 1.0, tx: 0.0, ty: 0.0)
  ## Identity transform matrix.


proc newTransform*(a: Float; b: Float; c: Float; d: Float; tx: Float; ty: Float): Transform {.inline, cdecl.} =
  ## Construct a new transform matrix.
  ## (a, b) is the x basis vector.
  ## (c, d) is the y basis vector.
  ## (tx, ty) is the translation.
  var t = Transform(a: a, b: b, c: c, d: d, tx: tx, ty: ty)
  return t


proc newTransposeTransform*(a: Float; c: Float; tx: Float; b: Float; d: Float; ty: Float): Transform {.inline, cdecl.} =
  ## Construct a new transform matrix in transposed order.
  var t = Transform(a: a, b: b, c: c, d: d, tx: tx, ty: ty)
  return t


proc inverse*(t: Transform): Transform {.inline, cdecl.} =
  ## Get the inverse of a transform matrix.
  var inv_det: Float = 1.0 div (t.a * t.d - t.c * t.b)
  return newTransposeTransform(t.d * inv_det, - (t.c * inv_det),
                                 (t.c * t.ty - t.tx * t.d) * inv_det,
                                 - (t.b * inv_det), t.a * inv_det,
                                 (t.tx * t.b - t.a * t.ty) * inv_det)


proc mult*(t1: Transform; t2: Transform): Transform {.inline, cdecl.} =
  ## Multiply two transformation matrices.
  return newTransposeTransform(t1.a * t2.a + t1.c * t2.b,
                                 t1.a * t2.c + t1.c * t2.d,
                                 t1.a * t2.tx + t1.c * t2.ty + t1.tx,
                                 t1.b * t2.a + t1.d * t2.b,
                                 t1.b * t2.c + t1.d * t2.d,
                                 t1.b * t2.tx + t1.d * t2.ty + t1.ty)


proc point*(t: Transform; p: Vect): Vect {.inline, cdecl.} =
  ## Transform an absolute point. (i.e. a vertex)
  return v(t.a * p.x + t.c * p.y + t.tx, t.b * p.x + t.d * p.y + t.ty)


proc vect*(t: Transform; v: Vect): Vect {.inline, cdecl.} =
  ## Transform a vector (i.e. a normal)
  return v(t.a * v.x + t.c * v.y, t.b * v.x + t.d * v.y)


proc transformBB*(t: Transform; bb: BB): BB {.inline, cdecl.} =
  ## Transform a cpBB.
  var center: Vect = center(bb)
  var hw: Float = (bb.r - bb.l) * 0.5
  var hh: Float = (bb.t - bb.b) * 0.5
  var
    a: Float = t.a * hw
    b: Float = t.c * hh
    d: Float = t.b * hw
    e: Float = t.d * hh
  var hw_max: Float = fmax(fabs(a + b), fabs(a - b))
  var hh_max: Float = fmax(fabs(d + e), fabs(d - e))
  return newForExtentsBB(point(t, center), hw_max, hh_max)


proc transformTranslate*(translate: Vect): Transform {.inline, cdecl.} =
  ## Create a transation matrix.
  return newTransposeTransform(1.0, 0.0, translate.x, 0.0, 1.0, translate.y)


proc transformScale*(scaleX: Float; scaleY: Float): Transform {.inline, cdecl.} =
  ## Create a scale matrix.
  return newTransposeTransform(scaleX, 0.0, 0.0, 0.0, scaleY, 0.0)


proc transformRotate*(radians: Float): Transform {.inline, cdecl.} =
  ## Create a rotation matrix.
  var rot: Vect = vforangle(radians)
  return newTransposeTransform(rot.x, - rot.y, 0.0, rot.y, rot.x, 0.0)


proc transformRigid*(translate: Vect; radians: Float): Transform {.inline, cdecl.} =
  ## Create a rigid transformation matrix. (transation + rotation)
  var rot: Vect = vforangle(radians)
  return newTransposeTransform(rot.x, - rot.y, translate.x, rot.y, rot.x,
      translate.y)


proc transformRigidInverse*(t: Transform): Transform {.inline, cdecl.} =
  ## Fast inverse of a rigid transformation matrix.
  return newTransposeTransform(t.d, - t.c, (t.c * t.ty - t.tx * t.d), - t.b,
                                 t.a, (t.tx * t.b - t.a * t.ty))

proc transformWrap*(outer: Transform; inner: Transform): Transform {.inline, cdecl.} =
  return mult(inverse(outer),
      mult(inner, outer))

proc transformWrapInverse*(outer: Transform; inner: Transform): Transform {.inline, cdecl.} =
  return mult(outer, mult(inner, inverse(outer)))

proc transformOrtho*(bb: BB): Transform {.inline, cdecl.} =
  return newTransposeTransform(2.0 div (bb.r - bb.l), 0.0,
                                - ((bb.r + bb.l) div (bb.r - bb.l)), 0.0,
                                2.0 div (bb.t - bb.b),
                                - ((bb.t + bb.b) div (bb.t - bb.b)))

proc transformBoneScale*(v0: Vect; v1: Vect): Transform {.inline, cdecl.} =
  var d: Vect = vsub(v1, v0)
  return newTransposeTransform(d.x, - d.y, v0.x, d.y, d.x, v0.y)

proc transformAxialScale*(axis: Vect; pivot: Vect; scale: Float): Transform {.inline, cdecl.} =
  var A: Float = axis.x * axis.y * (scale - 1.0)
  var B: Float = vdot(axis, pivot) * (1.0 - scale)
  return newTransposeTransform(scale * axis.x * axis.x + axis.y * axis.y, A,
                                 axis.x * B, A,
                                 axis.x * axis.x + scale * axis.y * axis.y,
                                 axis.y * B)







proc allocateSpaceHash*(): SpaceHash {.cdecl, importc: "cpSpaceHashAlloc".}
  ## Allocate a spatial hash.

proc initializeSpaceHash*(hash: SpaceHash; celldim: Float; numcells: cint; bbfunc: SpatialIndexBBFunc; staticIndex: SpatialIndex): SpatialIndex {.cdecl, importc: "cpSpaceHashInit".}
  ## Initialize a spatial hash.

proc newSpaceHash*(celldim: Float; cells: cint; bbfunc: SpatialIndexBBFunc; staticIndex: SpatialIndex): SpaceHash {.cdecl, importc: "cpSpaceHashNew".}
  ## Allocate and initialize a spatial hash.

proc resize*(hash: SpaceHash; celldim: Float; numcells: cint) {.cdecl, importc: "cpSpaceHashResize".}
  ## Change the cell dimensions and table size of the spatial hash to tune it.
  ## The cell dimensions should roughly match the average size of your objects
  ## and the table size should be ~10 larger than the number of objects inserted.
  ## Some trial and error is required to find the optimum numbers for efficiency.


proc allocateBBTree*(): BBTree {.cdecl, importc: "cpBBTreeAlloc".}
  ## Allocate a bounding box tree.

proc initializeBBTree*(tree: BBTree; bbfunc: SpatialIndexBBFunc; staticIndex: SpatialIndex): SpatialIndex {.cdecl, importc: "cpBBTreeInit".}
  ## Initialize a bounding box tree.

proc newBBTree*(bbfunc: SpatialIndexBBFunc; staticIndex: SpatialIndex): BBTree {.cdecl, importc: "cpBBTreeNew".}
  ## Allocate and initialize a bounding box tree.

proc optimize*(index: BBTree) {.cdecl, importc: "cpBBTreeOptimize".}
  ## Perform a static top down optimization of the tree.

proc `velocityFunc=`*(index: BBTree; `func`: BBTreeVelocityFunc) {.cdecl, importc: "cpBBTreeSetVelocityFunc".}
  ## Set the velocity function for the bounding box tree to enable temporal coherence.

proc allocateSweep1D*(): Sweep1D {.cdecl, importc: "cpSweep1DAlloc".}
  ## Allocate a 1D sort and sweep broadphase.

proc initializeSweep1D*(sweep: Sweep1D; bbfunc: SpatialIndexBBFunc; staticIndex: SpatialIndex): SpatialIndex {.cdecl, importc: "cpSweep1DInit".}
  ## Initialize a 1D sort and sweep broadphase.

proc newSweep1D*(bbfunc: SpatialIndexBBFunc; staticIndex: SpatialIndex): Sweep1D {.cdecl, importc: "cpSweep1DNew".}
  ## Allocate and initialize a 1D sort and sweep broadphase.

proc destroy*(index: SpatialIndex) {.destroy, cdecl, importc: "cpSpatialIndexFree".}
  ## Destroy and free a spatial index.
proc destroy*(index: Sweep1D) {.destroy, cdecl, importc: "cpSpatialIndexFree".}
proc destroy*(index: SpaceHash) {.destroy, cdecl, importc: "cpSpatialIndexFree".}
proc destroy*(index: BBTree) {.destroy, cdecl, importc: "cpSpatialIndexFree".}

proc collideStatic*(dynamicIndex: SpatialIndex; staticIndex: SpatialIndex; `func`: SpatialIndexQueryFunc; data: pointer) {.cdecl, importc: "cpSpatialIndexCollideStatic".}
  ## Collide the objects in `dynamicIndex` against the objects in `staticIndex` using the query callback function.

proc finalize*(index: SpatialIndex) {.inline, cdecl.} =
  ## Destroy a spatial index.
  if index.klass: index.klass.destroy(index)


proc count*(index: SpatialIndex): cint {.inline, cdecl.} =
  ## Get the number of objects in the spatial index.
  return index.klass.count(index)


proc each*(index: SpatialIndex; `func`: SpatialIndexIteratorFunc; data: pointer) {.inline, cdecl.} =
  ## Iterate the objects in the spatial index. `func` will be called once for each object.
  index.klass.each(index, `func`, data)


proc contains*(index: SpatialIndex; obj: pointer; hashid: HashValue): bool {.inline, cdecl.} =
  ## Returns true if the spatial index contains the given object.
  ## Most spatial indexes use hashed storage, so you must provide a hash value too.
  return index.klass.contains(index, obj, hashid)


proc insert*(index: SpatialIndex; obj: pointer; hashid: HashValue) {.inline, cdecl.} =
  ## Add an object to a spatial index.
  ## Most spatial indexes use hashed storage, so you must provide a hash value too.
  index.klass.insert(index, obj, hashid)


proc remove*(index: SpatialIndex; obj: pointer; hashid: HashValue) {.inline, cdecl.} =
  ## Remove an object from a spatial index.
  ## Most spatial indexes use hashed storage, so you must provide a hash value too.
  index.klass.remove(index, obj, hashid)


proc reindex*(index: SpatialIndex) {.inline, cdecl.} =
  ## Perform a full reindex of a spatial index.
  index.klass.reindex(index)


proc reindexObject*(index: SpatialIndex; obj: pointer; hashid: HashValue) {.inline, cdecl.} =
  ## Reindex a single object in the spatial index.
  index.klass.reindexObject(index, obj, hashid)


proc query*(index: SpatialIndex; obj: pointer; bb: BB; `func`: SpatialIndexQueryFunc; data: pointer) {.inline, cdecl.} =
  ## Perform a rectangle query against the spatial index, calling `func` for each potential match.
  index.klass.query(index, obj, bb, `func`, data)


proc segmentQuery*(index: SpatialIndex; obj: pointer; a: Vect; b: Vect; t_exit: Float; `func`: SpatialIndexSegmentQueryFunc; data: pointer) {.inline, cdecl.} =
  ## Perform a segment query against the spatial index, calling `func` for each potential match.
  index.klass.segmentQuery(index, obj, a, b, t_exit, `func`, data)


proc reindexQuery*(index: SpatialIndex; `func`: SpatialIndexQueryFunc; data: pointer) {.inline, cdecl.} =
  ## Simultaneously reindex and find all colliding objects.
  ## `func` will be called once for each potentially overlapping pair of objects found.
  ## If the spatial index was initialized with a static index, it will collide it's objects against that as well.
  index.klass.reindexQuery(index, `func`, data)


proc restitution*(arb: Arbiter): Float {.cdecl, importc: "cpArbiterGetRestitution".}
  ## Get the restitution (elasticity) that will be applied to the pair of colliding objects.

proc `restitution=`*(arb: Arbiter; restitution: Float) {.cdecl, importc: "cpArbiterSetRestitution".}
  ## Override the restitution (elasticity) that will be applied to the pair of colliding objects.

proc friction*(arb: Arbiter): Float {.cdecl, importc: "cpArbiterGetFriction".}
  ## Get the friction coefficient that will be applied to the pair of colliding objects.

proc `friction=`*(arb: Arbiter; friction: Float) {.cdecl, importc: "cpArbiterSetFriction".}
  ## Override the friction coefficient that will be applied to the pair of colliding objects.

proc surfaceVelocity*(arb: Arbiter): Vect {.cdecl, importc: "cpArbiterGetSurfaceVelocity".}

proc `surfaceVelocity=`*(arb: Arbiter; vr: Vect) {.cdecl, importc: "cpArbiterSetSurfaceVelocity".}

proc userData*(arb: Arbiter): DataPointer {.cdecl, importc: "cpArbiterGetUserData".}
  ## Get the user data pointer associated with this pair of colliding objects.

proc `userData=`*(arb: Arbiter; userData: DataPointer) {.cdecl, importc: "cpArbiterSetUserData".}
  ## Set a user data point associated with this pair of colliding objects.
  ## If you need to perform any cleanup for this pointer, you must do it yourself, in the separate callback for instance.

proc totalImpulse*(arb: Arbiter): Vect {.cdecl, importc: "cpArbiterTotalImpulse".}
  ## Calculate the total impulse including the friction that was applied by this arbiter.
  ## This function should only be called from a post-solve, post-step or cpBodyEachArbiter callback.

proc totalKE*(arb: Arbiter): Float {.cdecl, importc: "cpArbiterTotalKE".}
  ## Calculate the amount of energy lost in a collision including static, but not dynamic friction.
  ## This function should only be called from a post-solve, post-step or cpBodyEachArbiter callback.

proc ignore*(arb: Arbiter): bool {.cdecl, importc: "cpArbiterIgnore".}
  ## Mark a collision pair to be ignored until the two objects separate.
  ## Pre-solve and post-solve callbacks will not be called, but the separate callback will be called.

proc shapes*(arb: Arbiter; a: ptr Shape; b: ptr Shape) {.cdecl, importc: "cpArbiterGetShapes".}
  ## Return the colliding shapes involved for this arbiter.
  ## The order of their cpSpace.collision_type values will match
  ## the order set when the collision handler was registered.

proc bodies*(arb: Arbiter; a: ptr Body; b: ptr Body) {.cdecl, importc: "cpArbiterGetBodies".}
  ## Return the colliding bodies involved for this arbiter.
  ## The order of the cpSpace.collision_type the bodies are associated with values will match
  ## the order set when the collision handler was registered.

proc contactPointSet*(arb: Arbiter): ContactPointSet {.cdecl, importc: "cpArbiterGetContactPointSet".}
  ## Return a contact set from an arbiter.

proc `contactPointSet=`*(arb: Arbiter; set: ptr ContactPointSet) {.cdecl, importc: "cpArbiterSetContactPointSet".}
  ## Replace the contact point set for an arbiter.
  ## This can be a very powerful feature, but use it with caution!

proc isFirstContact*(arb: Arbiter): bool {.cdecl, importc: "cpArbiterIsFirstContact".}
  ## Returns true if this is the first step a pair of objects started colliding.

proc isRemoval*(arb: Arbiter): bool {.cdecl, importc: "cpArbiterIsRemoval".}
  ## Returns true if the separate callback is due to a shape being removed from the space.

proc count*(arb: Arbiter): cint {.cdecl, importc: "cpArbiterGetCount".}
  ## Get the number of contact points for this arbiter.

proc normal*(arb: Arbiter): Vect {.cdecl, importc: "cpArbiterGetNormal".}
  ## Get the normal of the collision.

proc pointA*(arb: Arbiter; i: cint): Vect {.cdecl, importc: "cpArbiterGetPointA".}
  ## Get the position of the `ith` contact point on the surface of the first shape.

proc pointB*(arb: Arbiter; i: cint): Vect {.cdecl, importc: "cpArbiterGetPointB".}
  ## Get the position of the `ith` contact point on the surface of the second shape.

proc depth*(arb: Arbiter; i: cint): Float {.cdecl, importc: "cpArbiterGetDepth".}
  ## Get the depth of the `ith` contact point.

proc callWildcardBeginA*(arb: Arbiter; space: Space): bool {.cdecl, importc: "cpArbiterCallWildcardBeginA".}
  ## If you want a custom callback to invoke the wildcard callback for the first collision type, you must call this function explicitly.
  ## You must decide how to handle the wildcard's return value since it may disagree with the other wildcard handler's return value or your own.

proc callWildcardBeginB*(arb: Arbiter; space: Space): bool {.cdecl, importc: "cpArbiterCallWildcardBeginB".}
  ## If you want a custom callback to invoke the wildcard callback for the second collision type, you must call this function explicitly.
  ## You must decide how to handle the wildcard's return value since it may disagree with the other wildcard handler's return value or your own.

proc callWildcardPreSolveA*(arb: Arbiter; space: Space): bool {.cdecl, importc: "cpArbiterCallWildcardPreSolveA".}
  ## If you want a custom callback to invoke the wildcard callback for the first collision type, you must call this function explicitly.
  ## You must decide how to handle the wildcard's return value since it may disagree with the other wildcard handler's return value or your own.

proc callWildcardPreSolveB*(arb: Arbiter; space: Space): bool {.cdecl, importc: "cpArbiterCallWildcardPreSolveB".}
  ## If you want a custom callback to invoke the wildcard callback for the second collision type, you must call this function explicitly.
  ## You must decide how to handle the wildcard's return value since it may disagree with the other wildcard handler's return value or your own.

proc callWildcardPostSolveA*(arb: Arbiter; space: Space) {.cdecl, importc: "cpArbiterCallWildcardPostSolveA".}
  ## If you want a custom callback to invoke the wildcard callback for the first collision type, you must call this function explicitly.

proc callWildcardPostSolveB*(arb: Arbiter; space: Space) {.cdecl, importc: "cpArbiterCallWildcardPostSolveB".}
  ## If you want a custom callback to invoke the wildcard callback for the second collision type, you must call this function explicitly.

proc callWildcardSeparateA*(arb: Arbiter; space: Space) {.cdecl, importc: "cpArbiterCallWildcardSeparateA".}
  ## If you want a custom callback to invoke the wildcard callback for the first collision type, you must call this function explicitly.

proc callWildcardSeparateB*(arb: Arbiter; space: Space) {.cdecl, importc: "cpArbiterCallWildcardSeparateB".}
  ## If you want a custom callback to invoke the wildcard callback for the second collision type, you must call this function explicitly.




proc allocateBody*(): Body {.cdecl, importc: "cpBodyAlloc".}
  ## Allocate a cpBody.

proc initializeBody*(body: Body; mass: Float; moment: Float): Body {.cdecl, importc: "cpBodyInit".}
  ## Initialize a cpBody.

proc newBody*(mass: Float; moment: Float): Body {.cdecl, importc: "cpBodyNew".}
  ## Allocate and initialize a cpBody.

proc newKinematicBody*(): Body {.cdecl, importc: "cpBodyNewKinematic".}
  ## Allocate and initialize a cpBody, and set it as a kinematic body.

proc newStaticBody*(): Body {.cdecl, importc: "cpBodyNewStatic".}
  ## Allocate and initialize a cpBody, and set it as a static body.

proc finalize*(body: Body) {.cdecl, importc: "cpBodyDestroy".}
  ## Destroy a cpBody.

proc destroy*(body: Body) {.destroy, cdecl, importc: "cpBodyFree".}
  ## Destroy and free a cpBody.

proc activate*(body: Body) {.cdecl, importc: "cpBodyActivate".}
  ## Wake up a sleeping or idle body.

proc activateStatic*(body: Body; filter: Shape) {.cdecl, importc: "cpBodyActivateStatic".}
  ## Wake up any sleeping or idle bodies touching a static body.

proc sleep*(body: Body) {.cdecl, importc: "cpBodySleep".}
  ## Force a body to fall asleep immediately.

proc sleepWithGroup*(body: Body; group: Body) {.cdecl, importc: "cpBodySleepWithGroup".}
  ## Force a body to fall asleep immediately along with other bodies in a group.

proc isSleeping*(body: Body): bool {.cdecl, importc: "cpBodyIsSleeping".}
  ## Returns true if the body is sleeping.

proc bodyType*(body: Body): BodyType {.cdecl, importc: "cpBodyGetType".}
  ## Get the type of the body.

proc `bodyType=`*(body: Body; `type`: BodyType) {.cdecl, importc: "cpBodySetType".}
  ## Set the type of the body.

proc space*(body: Body): Space {.cdecl, importc: "cpBodyGetSpace".}
  ## Get the space this body is added to.

proc mass*(body: Body): Float {.cdecl, importc: "cpBodyGetMass".}
  ## Get the mass of the body.

proc `mass=`*(body: Body; m: Float) {.cdecl, importc: "cpBodySetMass".}
  ## Set the mass of the body.

proc moment*(body: Body): Float {.cdecl, importc: "cpBodyGetMoment".}
  ## Get the moment of inertia of the body.

proc `moment=`*(body: Body; i: Float) {.cdecl, importc: "cpBodySetMoment".}
  ## Set the moment of inertia of the body.

proc position*(body: Body): Vect {.cdecl, importc: "cpBodyGetPosition".}
  ## Get the position of a body.

proc `position=`*(body: Body; pos: Vect) {.cdecl, importc: "cpBodySetPosition".}
  ## Set the position of the body.

proc centerOfGravity*(body: Body): Vect {.cdecl, importc: "cpBodyGetCenterOfGravity".}
  ## Get the offset of the center of gravity in body local coordinates.

proc `centerOfGravity=`*(body: Body; cog: Vect) {.cdecl, importc: "cpBodySetCenterOfGravity".}
  ## Set the offset of the center of gravity in body local coordinates.

proc velocity*(body: Body): Vect {.cdecl, importc: "cpBodyGetVelocity".}
  ## Get the velocity of the body.

proc `velocity=`*(body: Body; velocity: Vect) {.cdecl, importc: "cpBodySetVelocity".}
  ## Set the velocity of the body.

proc force*(body: Body): Vect {.cdecl, importc: "cpBodyGetForce".}
  ## Get the force applied to the body for the next time step.

proc `force=`*(body: Body; force: Vect) {.cdecl, importc: "cpBodySetForce".}
  ## Set the force applied to the body for the next time step.

proc angle*(body: Body): Float {.cdecl, importc: "cpBodyGetAngle".}
  ## Get the angle of the body.

proc `angle=`*(body: Body; a: Float) {.cdecl, importc: "cpBodySetAngle".}
  ## Set the angle of a body.

proc angularVelocity*(body: Body): Float {.cdecl, importc: "cpBodyGetAngularVelocity".}
  ## Get the angular velocity of the body.

proc `angularVelocity=`*(body: Body; angularVelocity: Float) {.cdecl, importc: "cpBodySetAngularVelocity".}
  ## Set the angular velocity of the body.

proc torque*(body: Body): Float {.cdecl, importc: "cpBodyGetTorque".}
  ## Get the torque applied to the body for the next time step.

proc `torque=`*(body: Body; torque: Float) {.cdecl, importc: "cpBodySetTorque".}
  ## Set the torque applied to the body for the next time step.

proc rotation*(body: Body): Vect {.cdecl, importc: "cpBodyGetRotation".}
  ## Get the rotation vector of the body. (The x basis vector of it's transform.)

proc userData*(body: Body): DataPointer {.cdecl, importc: "cpBodyGetUserData".}
  ## Get the user data pointer assigned to the body.

proc `userData=`*(body: Body; userData: DataPointer) {.cdecl, importc: "cpBodySetUserData".}
  ## Set the user data pointer assigned to the body.

proc `velocityUpdateFunc=`*(body: Body; velocityFunc: BodyVelocityFunc) {.cdecl, importc: "cpBodySetVelocityUpdateFunc".}
  ## Set the callback used to update a body's velocity.

proc `positionUpdateFunc=`*(body: Body; positionFunc: BodyPositionFunc) {.cdecl, importc: "cpBodySetPositionUpdateFunc".}
  ## Set the callback used to update a body's position.
  ## NOTE: It's not generally recommended to override this unless you call the default position update function.

proc updateVelocity*(body: Body; gravity: Vect; damping: Float; dt: Float) {.cdecl, importc: "cpBodyUpdateVelocity".}
  ## Default velocity integration function..

proc updatePosition*(body: Body; dt: Float) {.cdecl, importc: "cpBodyUpdatePosition".}
  ## Default position integration function.

proc localToWorld*(body: Body; point: Vect): Vect {.cdecl, importc: "cpBodyLocalToWorld".}
  ## Convert body relative/local coordinates to absolute/world coordinates.

proc worldToLocal*(body: Body; point: Vect): Vect {.cdecl, importc: "cpBodyWorldToLocal".}
  ## Convert body absolute/world coordinates to  relative/local coordinates.

proc applyForceAtWorldPoint*(body: Body; force: Vect; point: Vect) {.cdecl, importc: "cpBodyApplyForceAtWorldPoint".}
  ## Apply a force to a body. Both the force and point are expressed in world coordinates.

proc applyForceAtLocalPoint*(body: Body; force: Vect; point: Vect) {.cdecl, importc: "cpBodyApplyForceAtLocalPoint".}
  ## Apply a force to a body. Both the force and point are expressed in body local coordinates.

proc applyImpulseAtWorldPoint*(body: Body; impulse: Vect; point: Vect) {.cdecl, importc: "cpBodyApplyImpulseAtWorldPoint".}
  ## Apply an impulse to a body. Both the impulse and point are expressed in world coordinates.

proc applyImpulseAtLocalPoint*(body: Body; impulse: Vect; point: Vect) {.cdecl, importc: "cpBodyApplyImpulseAtLocalPoint".}
  ## Apply an impulse to a body. Both the impulse and point are expressed in body local coordinates.

proc velocityAtWorldPoint*(body: Body; point: Vect): Vect {.cdecl, importc: "cpBodyGetVelocityAtWorldPoint".}
  ## Get the velocity on a body (in world units) at a point on the body in world coordinates.

proc velocityAtLocalPoint*(body: Body; point: Vect): Vect {.cdecl, importc: "cpBodyGetVelocityAtLocalPoint".}
  ## Get the velocity on a body (in world units) at a point on the body in local coordinates.

proc kineticEnergy*(body: Body): Float {.cdecl, importc: "cpBodyKineticEnergy".}
  ## Get the amount of kinetic energy contained by the body.

proc eachShape*(body: Body; `func`: BodyShapeIteratorFunc; data: pointer) {.cdecl, importc: "cpBodyEachShape".}
  ## Call `func` once for each shape attached to `body` and added to the space.

proc eachConstraint*(body: Body; `func`: BodyConstraintIteratorFunc; data: pointer) {.cdecl, importc: "cpBodyEachConstraint".}
  ## Call `func` once for each constraint attached to `body` and added to the space.

proc eachArbiter(body: Body; `func`: BodyArbiterIteratorFunc; data: pointer) {.cdecl, importc: "cpBodyEachArbiter".}
  ## Call `func` once for each arbiter that is currently active on the body.

type BodyArbiterIteratorClosure* = proc (arbiter: Arbiter) {.raises: [].}

proc eachArbiter*(body: Body, closure: BodyArbiterIteratorClosure) =
  body.eachArbiter(proc (body: Body, arbiter: Arbiter, data: pointer) {.cdecl.} =
    cast[ptr BodyArbiterIteratorClosure](data)[](arbiter)
  , unsafeAddr closure)

var SHAPE_FILTER_ALL* = ShapeFilter(group: (cast[Group](0)))
  ## Collision filter value for a shape that will collide with anything except CP_SHAPE_FILTER_NONE.

var SHAPE_FILTER_NONE* = ShapeFilter(group: (cast[Group](0)))
  ## Collision filter value for a shape that does not collide with anything.

proc newShapeFilter*(group: Group; categories: Bitmask; mask: Bitmask): ShapeFilter {.inline, cdecl.} =
  ## Create a new collision filter.
  var filter = ShapeFilter(group: group)
  return filter

proc finalize*(shape: Shape) {.cdecl, importc: "cpShapeDestroy".}
  ## Destroy a shape.

proc destroy*(shape: Shape) {.destroy, cdecl, importc: "cpShapeFree".}
  ## Destroy and Free a shape.
proc destroy*(shape: PolyShape) {.destroy, cdecl, importc: "cpShapeFree".}
proc destroy*(shape: SegmentShape) {.destroy, cdecl, importc: "cpShapeFree".}
proc destroy*(shape: CircleShape) {.destroy, cdecl, importc: "cpShapeFree".}

proc kind*(shape: Shape): ShapeType {.cdecl, importc: "cpShapeGetType".}
  ## Get the type of this shape: cpCircleShape, cpSegmentShape or cpPolyShape.

proc cacheBB*(shape: Shape): BB {.cdecl, importc: "cpShapeCacheBB".}
  ## Update, cache and return the bounding box of a shape based on the body it's attached to.

proc update*(shape: Shape; transform: Transform): BB {.cdecl, importc: "cpShapeUpdate".}
  ## Update, cache and return the bounding box of a shape with an explicit transformation.

proc pointQuery*(shape: Shape; p: Vect; `out`: ptr PointQueryInfo): Float {.cdecl, importc: "cpShapePointQuery".}
  ## Perform a nearest point query. It finds the closest point on the surface of shape to a specific point.
  ## The value returned is the distance between the points. A negative distance means the point is inside the shape.

proc segmentQuery*(shape: Shape; a: Vect; b: Vect; radius: Float; info: ptr SegmentQueryInfo): bool {.cdecl, importc: "cpShapeSegmentQuery".}
  ## Perform a segment query against a shape. `info` must be a pointer to a valid cpSegmentQueryInfo structure.

proc collide*(a: Shape; b: Shape): ContactPointSet {.cdecl, importc: "cpShapesCollide".}
  ## Return contact information about two shapes.

proc space*(shape: Shape): Space {.cdecl, importc: "cpShapeGetSpace".}
  ## The cpSpace this body is added to.

proc body*(shape: Shape): Body {.cdecl, importc: "cpShapeGetBody".}
  ## The cpBody this shape is connected to.

proc `body=`*(shape: Shape; body: Body) {.cdecl, importc: "cpShapeSetBody".}
  ## Set the cpBody this shape is connected to.
  ## Can only be used if the shape is not currently added to a space.

proc mass*(shape: Shape): Float {.cdecl, importc: "cpShapeGetMass".}
  ## Get the mass of the shape if you are having Chipmunk calculate mass properties for you.

proc `mass=`*(shape: Shape; mass: Float) {.cdecl, importc: "cpShapeSetMass".}
  ## Set the mass of this shape to have Chipmunk calculate mass properties for you.

proc density*(shape: Shape): Float {.cdecl, importc: "cpShapeGetDensity".}
  ## Get the density of the shape if you are having Chipmunk calculate mass properties for you.

proc `density=`*(shape: Shape; density: Float) {.cdecl, importc: "cpShapeSetDensity".}
  ## Set the density  of this shape to have Chipmunk calculate mass properties for you.

proc moment*(shape: Shape): Float {.cdecl, importc: "cpShapeGetMoment".}
  ## Get the calculated moment of inertia for this shape.

proc area*(shape: Shape): Float {.cdecl, importc: "cpShapeGetArea".}
  ## Get the calculated area of this shape.

proc centerOfGravity*(shape: Shape): Vect {.cdecl, importc: "cpShapeGetCenterOfGravity".}
  ## Get the centroid of this shape.

proc bB*(shape: Shape): BB {.cdecl, importc: "cpShapeGetBB".}
  ## Get the bounding box that contains the shape given it's current position and angle.

proc sensor*(shape: Shape): bool {.cdecl, importc: "cpShapeGetSensor".}
  ## Get if the shape is set to be a sensor or not.

proc `sensor=`*(shape: Shape; sensor: bool) {.cdecl, importc: "cpShapeSetSensor".}
  ## Set if the shape is a sensor or not.

proc elasticity*(shape: Shape): Float {.cdecl, importc: "cpShapeGetElasticity".}
  ## Get the elasticity of this shape.

proc `elasticity=`*(shape: Shape; elasticity: Float) {.cdecl, importc: "cpShapeSetElasticity".}
  ## Set the elasticity of this shape.

proc friction*(shape: Shape): Float {.cdecl, importc: "cpShapeGetFriction".}
  ## Get the friction of this shape.

proc `friction=`*(shape: Shape; friction: Float) {.cdecl, importc: "cpShapeSetFriction".}
  ## Set the friction of this shape.

proc surfaceVelocity*(shape: Shape): Vect {.cdecl, importc: "cpShapeGetSurfaceVelocity".}
  ## Get the surface velocity of this shape.

proc `surfaceVelocity=`*(shape: Shape; surfaceVelocity: Vect) {.cdecl, importc: "cpShapeSetSurfaceVelocity".}
  ## Set the surface velocity of this shape.

proc userData*(shape: Shape): DataPointer {.cdecl, importc: "cpShapeGetUserData".}
  ## Get the user definable data pointer of this shape.

proc `userData=`*(shape: Shape; userData: DataPointer) {.cdecl, importc: "cpShapeSetUserData".}
  ## Set the user definable data pointer of this shape.

proc collisionType*(shape: Shape): CollisionType {.cdecl, importc: "cpShapeGetCollisionType".}
  ## Get the collision type of this shape.

proc `collisionType=`*(shape: Shape; collisionType: CollisionType) {.cdecl, importc: "cpShapeSetCollisionType".}
  ## Set the collision type of this shape.

proc filter*(shape: Shape): ShapeFilter {.cdecl, importc: "cpShapeGetFilter".}
  ## Get the collision filtering parameters of this shape.

proc `filter=`*(shape: Shape; filter: ShapeFilter) {.cdecl, importc: "cpShapeSetFilter".}
  ## Set the collision filtering parameters of this shape.

proc allocateCircleShape*(): CircleShape {.cdecl, importc: "cpCircleShapeAlloc".}
  ## Allocate a circle shape.

proc initializeCircleShape*(circle: CircleShape; body: Body; radius: Float; offset: Vect): CircleShape {.cdecl, importc: "cpCircleShapeInit".}
  ## Initialize a circle shape.

proc newCircleShape*(body: Body; radius: Float; offset: Vect): CircleShape {.cdecl, importc: "cpCircleShapeNew".}
  ## Allocate and initialize a circle shape.
  ## offset: The offset from the center of gravity.

proc offset*(shape: CircleShape): Vect {.cdecl, importc: "cpCircleShapeGetOffset".}
  ## Get the offset of a circle shape.

proc radius*(shape: CircleShape): Float {.cdecl, importc: "cpCircleShapeGetRadius".}
  ## Get the radius of a circle shape.

proc allocateSegmentShape*(): SegmentShape {.cdecl, importc: "cpSegmentShapeAlloc".}
  ## Allocate a segment shape.

proc initializeSegmentShape*(seg: SegmentShape; body: Body; a: Vect; b: Vect; radius: Float): SegmentShape {.cdecl, importc: "cpSegmentShapeInit".}
  ## Initialize a segment shape.

proc newSegmentShape*(body: Body; a: Vect; b: Vect; radius: Float): SegmentShape {.cdecl, importc: "cpSegmentShapeNew".}
  ## Allocate and initialize a segment shape.

proc `neighbors=`*(shape: SegmentShape; prev: Vect; next: Vect) {.cdecl, importc: "cpSegmentShapeSetNeighbors".}
  ## Let Chipmunk know about the geometry of adjacent segments to avoid colliding with endcaps.

proc a*(shape: SegmentShape): Vect {.cdecl, importc: "cpSegmentShapeGetA".}
  ## Get the first endpoint of a segment shape.

proc b*(shape: SegmentShape): Vect {.cdecl, importc: "cpSegmentShapeGetB".}
  ## Get the second endpoint of a segment shape.

proc normal*(shape: SegmentShape): Vect {.cdecl, importc: "cpSegmentShapeGetNormal".}
  ## Get the normal of a segment shape.

proc radius*(shape: SegmentShape): Float {.cdecl, importc: "cpSegmentShapeGetRadius".}
  ## Get the first endpoint of a segment shape.

proc allocatePolyShape*(): PolyShape {.cdecl, importc: "cpPolyShapeAlloc".}
  ## Allocate a polygon shape.

proc initializePolyShape*(poly: PolyShape; body: Body; count: cint; verts: ptr Vect; transform: Transform; radius: Float): PolyShape {.cdecl, importc: "cpPolyShapeInit".}
  ## Initialize a polygon shape with rounded corners.
  ## A convex hull will be created from the vertexes.

proc initializePolyShape*(poly: PolyShape; body: Body; count: cint; verts: ptr Vect; radius: Float): PolyShape {.cdecl, importc: "cpPolyShapeInitRaw".}
  ## Initialize a polygon shape with rounded corners.
  ## The vertexes must be convex with a counter-clockwise winding.

proc newPolyShape*(body: Body; count: cint; verts: ptr Vect; transform: Transform; radius: Float): PolyShape {.cdecl, importc: "cpPolyShapeNew".}
  ## Allocate and initialize a polygon shape with rounded corners.
  ## A convex hull will be created from the vertexes.

# proc newPolyShape*(body: Body; count: cint; verts: ptr Vect; radius: Float): PolyShape {.cdecl, importc: "cpPolyShapeNewRaw".}
## Allocate and initialize a polygon shape with rounded corners.
## The vertexes must be convex with a counter-clockwise winding.

proc initializeBoxShape*(poly: PolyShape; body: Body; width: Float; height: Float; radius: Float): PolyShape {.cdecl, importc: "cpBoxShapeInit".}
  ## Initialize a box shaped polygon shape with rounded corners.

proc initializeBoxShape*(poly: PolyShape; body: Body; box: BB; radius: Float): PolyShape {.cdecl, importc: "cpBoxShapeInit2".}
  ## Initialize an offset box shaped polygon shape with rounded corners.

proc newBoxShape*(body: Body; width: Float; height: Float; radius: Float): PolyShape {.cdecl, importc: "cpBoxShapeNew".}
  ## Allocate and initialize a box shaped polygon shape.

proc newBoxShape*(body: Body; box: BB; radius: Float): PolyShape {.cdecl, importc: "cpBoxShapeNew2".}
  ## Allocate and initialize an offset box shaped polygon shape.

proc count*(shape: PolyShape): cint {.cdecl, importc: "cpPolyShapeGetCount".}
  ## Get the number of verts in a polygon shape.

proc vert*(shape: PolyShape; index: cint): Vect {.cdecl, importc: "cpPolyShapeGetVert".}
  ## Get the `ith` vertex of a polygon shape.

proc radius*(shape: PolyShape): Float {.cdecl, importc: "cpPolyShapeGetRadius".}
  ## Get the radius of a polygon shape.

proc finalize*(constraint: Constraint) {.cdecl, importc: "cpConstraintDestroy".}
  ## Destroy a constraint.

proc destroy*(constraint: Constraint) {.destroy, cdecl, importc: "cpConstraintFree".}
  ## Destroy and free a constraint.
# proc destroy*(constraint: PinJoint) {.destroy, cdecl, importc: "cpConstraintFree".}
# proc destroy*(constraint: DampedSpring) {.destroy, cdecl, importc: "cpConstraintFree".}
# proc destroy*(constraint: RotaryLimitJoint) {.destroy, cdecl, importc: "cpConstraintFree".}
# proc destroy*(constraint: SlideJoint) {.destroy, cdecl, importc: "cpConstraintFree".}
# proc destroy*(constraint: GearJoint) {.destroy, cdecl, importc: "cpConstraintFree".}
# proc destroy*(constraint: DampedRotarySpring) {.destroy, cdecl, importc: "cpConstraintFree".}
# proc destroy*(constraint: GrooveJoint) {.destroy, cdecl, importc: "cpConstraintFree".}
# proc destroy*(constraint: RatchetJoint) {.destroy, cdecl, importc: "cpConstraintFree".}
# proc destroy*(constraint: SimpleMotor) {.destroy, cdecl, importc: "cpConstraintFree".}
# proc destroy*(constraint: PivotJoint) {.destroy, cdecl, importc: "cpConstraintFree".}

proc space*(constraint: Constraint): Space {.cdecl, importc: "cpConstraintGetSpace".}
  ## Get the cpSpace this constraint is added to.

proc bodyA*(constraint: Constraint): Body {.cdecl, importc: "cpConstraintGetBodyA".}
  ## Get the first body the constraint is attached to.

proc bodyB*(constraint: Constraint): Body {.cdecl, importc: "cpConstraintGetBodyB".}
  ## Get the second body the constraint is attached to.

proc maxForce*(constraint: Constraint): Float {.cdecl, importc: "cpConstraintGetMaxForce".}
  ## Get the maximum force that this constraint is allowed to use.

proc `maxForce=`*(constraint: Constraint; maxForce: Float) {.cdecl, importc: "cpConstraintSetMaxForce".}
  ## Set the maximum force that this constraint is allowed to use. (defaults to INFINITY)

proc errorBias*(constraint: Constraint): Float {.cdecl, importc: "cpConstraintGetErrorBias".}
  ## Get rate at which joint error is corrected.

proc `errorBias=`*(constraint: Constraint; errorBias: Float) {.cdecl, importc: "cpConstraintSetErrorBias".}
  ## Set rate at which joint error is corrected.
  ## Defaults to pow(1.0 - 0.1, 60.0) meaning that it will
  ## correct 10% of the error every 1/60th of a second.

proc maxBias*(constraint: Constraint): Float {.cdecl, importc: "cpConstraintGetMaxBias".}
  ## Get the maximum rate at which joint error is corrected.

proc `maxBias=`*(constraint: Constraint; maxBias: Float) {.cdecl, importc: "cpConstraintSetMaxBias".}
  ## Set the maximum rate at which joint error is corrected. (defaults to INFINITY)

proc collideBodies*(constraint: Constraint): bool {.cdecl, importc: "cpConstraintGetCollideBodies".}
  ## Get if the two bodies connected by the constraint are allowed to collide or not.

proc `collideBodies=`*(constraint: Constraint; collideBodies: bool) {.cdecl, importc: "cpConstraintSetCollideBodies".}
  ## Set if the two bodies connected by the constraint are allowed to collide or not. (defaults to cpFalse)

proc preSolveFunc*(constraint: Constraint): ConstraintPreSolveFunc {.cdecl, importc: "cpConstraintGetPreSolveFunc".}
  ## Get the pre-solve function that is called before the solver runs.

proc `preSolveFunc=`*(constraint: Constraint; preSolveFunc: ConstraintPreSolveFunc) {.cdecl, importc: "cpConstraintSetPreSolveFunc".}
  ## Set the pre-solve function that is called before the solver runs.

proc postSolveFunc*(constraint: Constraint): ConstraintPostSolveFunc {.cdecl, importc: "cpConstraintGetPostSolveFunc".}
  ## Get the post-solve function that is called before the solver runs.

proc `postSolveFunc=`*(constraint: Constraint; postSolveFunc: ConstraintPostSolveFunc) {.cdecl, importc: "cpConstraintSetPostSolveFunc".}
  ## Set the post-solve function that is called before the solver runs.

proc userData*(constraint: Constraint): DataPointer {.cdecl, importc: "cpConstraintGetUserData".}
  ## Get the user definable data pointer for this constraint

proc `userData=`*(constraint: Constraint; userData: DataPointer) {.cdecl, importc: "cpConstraintSetUserData".}
  ## Set the user definable data pointer for this constraint

proc impulse*(constraint: Constraint): Float {.cdecl, importc: "cpConstraintGetImpulse".}
  ## Get the last impulse applied by this constraint.

proc isPinJoint*(constraint: Constraint): bool {.cdecl, importc: "cpConstraintIsPinJoint".}
  ## Check if a constraint is a pin joint.

proc allocatePinJoint*(): PinJoint {.cdecl, importc: "cpPinJointAlloc".}
  ## Allocate a pin joint.

proc initializePinJoint*(joint: PinJoint; a: Body; b: Body; anchorA: Vect; anchorB: Vect): PinJoint {.cdecl, importc: "cpPinJointInit".}
  ## Initialize a pin joint.

proc newPinJoint*(a: Body; b: Body; anchorA: Vect; anchorB: Vect): PinJoint {.cdecl, importc: "cpPinJointNew".}
  ## Allocate and initialize a pin joint.

proc anchorA*(constraint: PinJoint): Vect {.cdecl, importc: "cpPinJointGetAnchorA".}
  ## Get the location of the first anchor relative to the first body.

proc `anchorA=`*(constraint: PinJoint; anchorA: Vect) {.cdecl, importc: "cpPinJointSetAnchorA".}
  ## Set the location of the first anchor relative to the first body.

proc anchorB*(constraint: PinJoint): Vect {.cdecl, importc: "cpPinJointGetAnchorB".}
  ## Get the location of the second anchor relative to the second body.

proc `anchorB=`*(constraint: PinJoint; anchorB: Vect) {.cdecl, importc: "cpPinJointSetAnchorB".}
  ## Set the location of the second anchor relative to the second body.

proc dist*(constraint: PinJoint): Float {.cdecl, importc: "cpPinJointGetDist".}
  ## Get the distance the joint will maintain between the two anchors.

proc `dist=`*(constraint: PinJoint; dist: Float) {.cdecl, importc: "cpPinJointSetDist".}
  ## Set the distance the joint will maintain between the two anchors.

proc isSlideJoint*(constraint: Constraint): bool {.cdecl, importc: "cpConstraintIsSlideJoint".}
  ## Check if a constraint is a slide joint.

proc allocateSlideJoint*(): SlideJoint {.cdecl, importc: "cpSlideJointAlloc".}
  ## Allocate a slide joint.

proc initializeSlideJoint*(joint: SlideJoint; a: Body; b: Body; anchorA: Vect; anchorB: Vect; min: Float; max: Float): SlideJoint {.cdecl, importc: "cpSlideJointInit".}
  ## Initialize a slide joint.

proc newSlideJoint*(a: Body; b: Body; anchorA: Vect; anchorB: Vect; min: Float; max: Float): SlideJoint {.cdecl, importc: "cpSlideJointNew".}
  ## Allocate and initialize a slide joint.

proc anchorA*(constraint: SlideJoint): Vect {.cdecl, importc: "cpSlideJointGetAnchorA".}
  ## Get the location of the first anchor relative to the first body.

proc `anchorA=`*(constraint: SlideJoint; anchorA: Vect) {.cdecl, importc: "cpSlideJointSetAnchorA".}
  ## Set the location of the first anchor relative to the first body.

proc anchorB*(constraint: SlideJoint): Vect {.cdecl, importc: "cpSlideJointGetAnchorB".}
  ## Get the location of the second anchor relative to the second body.

proc `anchorB=`*(constraint: SlideJoint; anchorB: Vect) {.cdecl, importc: "cpSlideJointSetAnchorB".}
  ## Set the location of the second anchor relative to the second body.

proc min*(constraint: SlideJoint): Float {.cdecl, importc: "cpSlideJointGetMin".}
  ## Get the minimum distance the joint will maintain between the two anchors.

proc `min=`*(constraint: SlideJoint; min: Float) {.cdecl, importc: "cpSlideJointSetMin".}
  ## Set the minimum distance the joint will maintain between the two anchors.

proc max*(constraint: SlideJoint): Float {.cdecl, importc: "cpSlideJointGetMax".}
  ## Get the maximum distance the joint will maintain between the two anchors.

proc `max=`*(constraint: SlideJoint; max: Float) {.cdecl, importc: "cpSlideJointSetMax".}
  ## Set the maximum distance the joint will maintain between the two anchors.

proc isPivotJoint*(constraint: Constraint): bool {.cdecl, importc: "cpConstraintIsPivotJoint".}
  ## Check if a constraint is a pivot joint.

proc allocatePivotJoint*(): PivotJoint {.cdecl, importc: "cpPivotJointAlloc".}
  ## Allocate a pivot joint

proc initializePivotJoint*(joint: PivotJoint; a: Body; b: Body; anchorA: Vect; anchorB: Vect): PivotJoint {.cdecl, importc: "cpPivotJointInit".}
  ## Initialize a pivot joint.

proc newPivotJoint*(a: Body; b: Body; pivot: Vect): PivotJoint {.cdecl, importc: "cpPivotJointNew".}
  ## Allocate and initialize a pivot joint.

proc newPivotJoint*(a: Body; b: Body; anchorA: Vect; anchorB: Vect): PivotJoint {.cdecl, importc: "cpPivotJointNew2".}
  ## Allocate and initialize a pivot joint with specific anchors.

proc anchorA*(constraint: PivotJoint): Vect {.cdecl, importc: "cpPivotJointGetAnchorA".}
  ## Get the location of the first anchor relative to the first body.

proc `anchorA=`*(constraint: PivotJoint; anchorA: Vect) {.cdecl, importc: "cpPivotJointSetAnchorA".}
  ## Set the location of the first anchor relative to the first body.

proc anchorB*(constraint: PivotJoint): Vect {.cdecl, importc: "cpPivotJointGetAnchorB".}
  ## Get the location of the second anchor relative to the second body.

proc `anchorB=`*(constraint: PivotJoint; anchorB: Vect) {.cdecl, importc: "cpPivotJointSetAnchorB".}
  ## Set the location of the second anchor relative to the second body.

proc isGrooveJoint*(constraint: Constraint): bool {.cdecl, importc: "cpConstraintIsGrooveJoint".}
  ## Check if a constraint is a slide joint.

proc allocateGrooveJoint*(): GrooveJoint {.cdecl, importc: "cpGrooveJointAlloc".}
  ## Allocate a groove joint.

proc initializeGrooveJoint*(joint: GrooveJoint; a: Body; b: Body; groove_a: Vect; groove_b: Vect; anchorB: Vect): GrooveJoint {.cdecl, importc: "cpGrooveJointInit".}
  ## Initialize a groove joint.

proc newGrooveJoint*(a: Body; b: Body; groove_a: Vect; groove_b: Vect; anchorB: Vect): GrooveJoint {.cdecl, importc: "cpGrooveJointNew".}
  ## Allocate and initialize a groove joint.

proc grooveA*(constraint: GrooveJoint): Vect {.cdecl, importc: "cpGrooveJointGetGrooveA".}
  ## Get the first endpoint of the groove relative to the first body.

proc `grooveA=`*(constraint: GrooveJoint; grooveA: Vect) {.cdecl, importc: "cpGrooveJointSetGrooveA".}
  ## Set the first endpoint of the groove relative to the first body.

proc grooveB*(constraint: GrooveJoint): Vect {.cdecl, importc: "cpGrooveJointGetGrooveB".}
  ## Get the first endpoint of the groove relative to the first body.

proc `grooveB=`*(constraint: GrooveJoint; grooveB: Vect) {.cdecl, importc: "cpGrooveJointSetGrooveB".}
  ## Set the first endpoint of the groove relative to the first body.

proc anchorB*(constraint: GrooveJoint): Vect {.cdecl, importc: "cpGrooveJointGetAnchorB".}
  ## Get the location of the second anchor relative to the second body.

proc `anchorB=`*(constraint: GrooveJoint; anchorB: Vect) {.cdecl, importc: "cpGrooveJointSetAnchorB".}
  ## Set the location of the second anchor relative to the second body.

proc isDampedSpring*(constraint: Constraint): bool {.cdecl, importc: "cpConstraintIsDampedSpring".}
  ## Check if a constraint is a slide joint.

proc allocateDampedSpring*(): DampedSpring {.cdecl, importc: "cpDampedSpringAlloc".}
  ## Allocate a damped spring.

proc initializeDampedSpring*(joint: DampedSpring; a: Body; b: Body; anchorA: Vect; anchorB: Vect; restLength: Float; stiffness: Float; damping: Float): DampedSpring {.cdecl, importc: "cpDampedSpringInit".}
  ## Initialize a damped spring.

proc newDampedSpring*(a: Body; b: Body; anchorA: Vect; anchorB: Vect; restLength: Float; stiffness: Float; damping: Float): DampedSpring {.cdecl, importc: "cpDampedSpringNew".}
  ## Allocate and initialize a damped spring.

proc anchorA*(constraint: DampedSpring): Vect {.cdecl, importc: "cpDampedSpringGetAnchorA".}
  ## Get the location of the first anchor relative to the first body.

proc `anchorA=`*(constraint: DampedSpring; anchorA: Vect) {.cdecl, importc: "cpDampedSpringSetAnchorA".}
  ## Set the location of the first anchor relative to the first body.

proc anchorB*(constraint: DampedSpring): Vect {.cdecl, importc: "cpDampedSpringGetAnchorB".}
  ## Get the location of the second anchor relative to the second body.

proc `anchorB=`*(constraint: DampedSpring; anchorB: Vect) {.cdecl, importc: "cpDampedSpringSetAnchorB".}
  ## Set the location of the second anchor relative to the second body.

proc restLength*(constraint: DampedSpring): Float {.cdecl, importc: "cpDampedSpringGetRestLength".}
  ## Get the rest length of the spring.

proc `restLength=`*(constraint: DampedSpring; restLength: Float) {.cdecl, importc: "cpDampedSpringSetRestLength".}
  ## Set the rest length of the spring.

proc stiffness*(constraint: DampedSpring): Float {.cdecl, importc: "cpDampedSpringGetStiffness".}
  ## Get the stiffness of the spring in force/distance.

proc `stiffness=`*(constraint: DampedSpring; stiffness: Float) {.cdecl, importc: "cpDampedSpringSetStiffness".}
  ## Set the stiffness of the spring in force/distance.

proc damping*(constraint: DampedSpring): Float {.cdecl, importc: "cpDampedSpringGetDamping".}
  ## Get the damping of the spring.

proc `damping=`*(constraint: DampedSpring; damping: Float) {.cdecl, importc: "cpDampedSpringSetDamping".}
  ## Set the damping of the spring.

proc springForceFunc*(constraint: DampedSpring): DampedSpringForceFunc {.cdecl, importc: "cpDampedSpringGetSpringForceFunc".}
  ## Get the damping of the spring.

proc `springForceFunc=`*(constraint: DampedSpring; springForceFunc: DampedSpringForceFunc) {.cdecl, importc: "cpDampedSpringSetSpringForceFunc".}
  ## Set the damping of the spring.

proc isDampedRotarySpring*(constraint: Constraint): bool {.cdecl, importc: "cpConstraintIsDampedRotarySpring".}
  ## Check if a constraint is a damped rotary springs.

proc allocateDampedRotarySpring*(): DampedRotarySpring {.cdecl, importc: "cpDampedRotarySpringAlloc".}
  ## Allocate a damped rotary spring.

proc initializeDampedRotarySpring*(joint: DampedRotarySpring; a: Body; b: Body; restAngle: Float; stiffness: Float; damping: Float): DampedRotarySpring {.cdecl, importc: "cpDampedRotarySpringInit".}
  ## Initialize a damped rotary spring.

proc newDampedRotarySpring*(a: Body; b: Body; restAngle: Float; stiffness: Float; damping: Float): DampedRotarySpring {.cdecl, importc: "cpDampedRotarySpringNew".}
  ## Allocate and initialize a damped rotary spring.

proc restAngle*(constraint: DampedRotarySpring): Float {.cdecl, importc: "cpDampedRotarySpringGetRestAngle".}
  ## Get the rest length of the spring.

proc `restAngle=`*(constraint: DampedRotarySpring; restAngle: Float) {.cdecl, importc: "cpDampedRotarySpringSetRestAngle".}
  ## Set the rest length of the spring.

proc stiffness*(constraint: DampedRotarySpring): Float {.cdecl, importc: "cpDampedRotarySpringGetStiffness".}
  ## Get the stiffness of the spring in force/distance.

proc `stiffness=`*(constraint: DampedRotarySpring; stiffness: Float) {.cdecl, importc: "cpDampedRotarySpringSetStiffness".}
  ## Set the stiffness of the spring in force/distance.

proc damping*(constraint: DampedRotarySpring): Float {.cdecl, importc: "cpDampedRotarySpringGetDamping".}
  ## Get the damping of the spring.

proc `damping=`*(constraint: DampedRotarySpring; damping: Float) {.cdecl, importc: "cpDampedRotarySpringSetDamping".}
  ## Set the damping of the spring.

proc springTorqueFunc*(constraint: DampedRotarySpring): DampedRotarySpringTorqueFunc {.cdecl, importc: "cpDampedRotarySpringGetSpringTorqueFunc".}
  ## Get the damping of the spring.

proc `springTorqueFunc=`*(constraint: DampedRotarySpring; springTorqueFunc: DampedRotarySpringTorqueFunc) {.cdecl, importc: "cpDampedRotarySpringSetSpringTorqueFunc".}
  ## Set the damping of the spring.

proc isRotaryLimitJoint*(constraint: Constraint): bool {.cdecl, importc: "cpConstraintIsRotaryLimitJoint".}
  ## Check if a constraint is a damped rotary springs.

proc allocateRotaryLimitJoint*(): RotaryLimitJoint {.cdecl, importc: "cpRotaryLimitJointAlloc".}
  ## Allocate a damped rotary limit joint.

proc initializeRotaryLimitJoint*(joint: RotaryLimitJoint; a: Body; b: Body; min: Float; max: Float): RotaryLimitJoint {.cdecl, importc: "cpRotaryLimitJointInit".}
  ## Initialize a damped rotary limit joint.

proc newRotaryLimitJoint*(a: Body; b: Body; min: Float; max: Float): RotaryLimitJoint {.cdecl, importc: "cpRotaryLimitJointNew".}
  ## Allocate and initialize a damped rotary limit joint.

proc min*(constraint: RotaryLimitJoint): Float {.cdecl, importc: "cpRotaryLimitJointGetMin".}
  ## Get the minimum distance the joint will maintain between the two anchors.

proc `min=`*(constraint: RotaryLimitJoint; min: Float) {.cdecl, importc: "cpRotaryLimitJointSetMin".}
  ## Set the minimum distance the joint will maintain between the two anchors.

proc max*(constraint: RotaryLimitJoint): Float {.cdecl, importc: "cpRotaryLimitJointGetMax".}
  ## Get the maximum distance the joint will maintain between the two anchors.

proc `max=`*(constraint: RotaryLimitJoint; max: Float) {.cdecl, importc: "cpRotaryLimitJointSetMax".}
  ## Set the maximum distance the joint will maintain between the two anchors.

proc isRatchetJoint*(constraint: Constraint): bool {.cdecl, importc: "cpConstraintIsRatchetJoint".}
  ## Check if a constraint is a damped rotary springs.

proc allocateRatchetJoint*(): RatchetJoint {.cdecl, importc: "cpRatchetJointAlloc".}
  ## Allocate a ratchet joint.

proc initializeRatchetJoint*(joint: RatchetJoint; a: Body; b: Body; phase: Float; ratchet: Float): RatchetJoint {.cdecl, importc: "cpRatchetJointInit".}
  ## Initialize a ratched joint.

proc newRatchetJoint*(a: Body; b: Body; phase: Float; ratchet: Float): RatchetJoint {.cdecl, importc: "cpRatchetJointNew".}
  ## Allocate and initialize a ratchet joint.

proc angle*(constraint: RatchetJoint): Float {.cdecl, importc: "cpRatchetJointGetAngle".}
  ## Get the angle of the current ratchet tooth.

proc `angle=`*(constraint: RatchetJoint; angle: Float) {.cdecl, importc: "cpRatchetJointSetAngle".}
  ## Set the angle of the current ratchet tooth.

proc phase*(constraint: RatchetJoint): Float {.cdecl, importc: "cpRatchetJointGetPhase".}
  ## Get the phase offset of the ratchet.

proc `phase=`*(constraint: RatchetJoint; phase: Float) {.cdecl, importc: "cpRatchetJointSetPhase".}
  ## Get the phase offset of the ratchet.

proc ratchet*(constraint: RatchetJoint): Float {.cdecl, importc: "cpRatchetJointGetRatchet".}
  ## Get the angular distance of each ratchet.

proc `ratchet=`*(constraint: RatchetJoint; ratchet: Float) {.cdecl, importc: "cpRatchetJointSetRatchet".}
  ## Set the angular distance of each ratchet.

proc isGearJoint*(constraint: Constraint): bool {.cdecl, importc: "cpConstraintIsGearJoint".}
  ## Check if a constraint is a damped rotary springs.

proc allocateGearJoint*(): GearJoint {.cdecl, importc: "cpGearJointAlloc".}
  ## Allocate a gear joint.

proc initializeGearJoint*(joint: GearJoint; a: Body; b: Body; phase: Float; ratio: Float): GearJoint {.cdecl, importc: "cpGearJointInit".}
  ## Initialize a gear joint.

proc newGearJoint*(a: Body; b: Body; phase: Float; ratio: Float): GearJoint {.cdecl, importc: "cpGearJointNew".}
  ## Allocate and initialize a gear joint.

proc phase*(constraint: GearJoint): Float {.cdecl, importc: "cpGearJointGetPhase".}
  ## Get the phase offset of the gears.

proc `phase=`*(constraint: GearJoint; phase: Float) {.cdecl, importc: "cpGearJointSetPhase".}
  ## Set the phase offset of the gears.

proc ratio*(constraint: GearJoint): Float {.cdecl, importc: "cpGearJointGetRatio".}
  ## Get the angular distance of each ratchet.

proc `ratio=`*(constraint: GearJoint; ratio: Float) {.cdecl, importc: "cpGearJointSetRatio".}
  ## Set the ratio of a gear joint.

proc isSimpleMotor*(constraint: Constraint): bool {.cdecl, importc: "cpConstraintIsSimpleMotor".}
  ## Check if a constraint is a damped rotary springs.

proc allocateSimpleMotor*(): SimpleMotor {.cdecl, importc: "cpSimpleMotorAlloc".}
  ## Allocate a simple motor.

proc initializeSimpleMotor*(joint: SimpleMotor; a: Body; b: Body; rate: Float): SimpleMotor {.cdecl, importc: "cpSimpleMotorInit".}
  ## initialize a simple motor.

proc newSimpleMotor*(a: Body; b: Body; rate: Float): SimpleMotor {.cdecl, importc: "cpSimpleMotorNew".}
  ## Allocate and initialize a simple motor.

proc rate*(constraint: SimpleMotor): Float {.cdecl, importc: "cpSimpleMotorGetRate".}
  ## Get the rate of the motor.

proc `rate=`*(constraint: SimpleMotor; rate: Float) {.cdecl, importc: "cpSimpleMotorSetRate".}
  ## Set the rate of the motor.

proc allocateSpace*(): Space {.cdecl, importc: "cpSpaceAlloc".}
  ## Allocate a cpSpace.

proc initializeSpace*(space: Space): Space {.cdecl, importc: "cpSpaceInit".}
  ## Initialize a cpSpace.

proc newSpace*(): Space {.cdecl, importc: "cpSpaceNew".}
  ## Allocate and initialize a cpSpace.

proc finalize*(space: Space) {.cdecl, importc: "cpSpaceDestroy".}
  ## Destroy a cpSpace.

proc destroy*(space: Space) {.destroy, cdecl, importc: "cpSpaceFree".}
  ## Destroy and free a cpSpace.

proc iterations*(space: Space): cint {.cdecl, importc: "cpSpaceGetIterations".}
proc `iterations=`*(space: Space; iterations: cint) {.cdecl, importc: "cpSpaceSetIterations".}
  ## Number of iterations to use in the impulse solver to solve contacts and other constraints.

proc gravity*(space: Space): Vect {.cdecl, importc: "cpSpaceGetGravity".}
proc `gravity=`*(space: Space; gravity: Vect) {.cdecl, importc: "cpSpaceSetGravity".}
  ## Gravity to pass to rigid bodies when integrating velocity.

proc damping*(space: Space): Float {.cdecl, importc: "cpSpaceGetDamping".}
proc `damping=`*(space: Space; damping: Float) {.cdecl, importc: "cpSpaceSetDamping".}
  ## Damping rate expressed as the fraction of velocity bodies retain each second.
  ## A value of 0.9 would mean that each body's velocity will drop 10% per second.
  ## The default value is 1.0, meaning no damping is applied.
  ## @note This damping value is different than those of cpDampedSpring and cpDampedRotarySpring.

proc idleSpeedThreshold*(space: Space): Float {.cdecl, importc: "cpSpaceGetIdleSpeedThreshold".}
proc `idleSpeedThreshold=`*(space: Space; idleSpeedThreshold: Float) {.cdecl, importc: "cpSpaceSetIdleSpeedThreshold".}
  ## Speed threshold for a body to be considered idle.
  ## The default value of 0 means to let the space guess a good threshold based on gravity.

proc sleepTimeThreshold*(space: Space): Float {.cdecl, importc: "cpSpaceGetSleepTimeThreshold".}
proc `sleepTimeThreshold=`*(space: Space; sleepTimeThreshold: Float) {.cdecl, importc: "cpSpaceSetSleepTimeThreshold".}
  ## Time a group of bodies must remain idle in order to fall asleep.
  ## Enabling sleeping also implicitly enables the the contact graph.
  ## The default value of INFINITY disables the sleeping algorithm.

proc collisionSlop*(space: Space): Float {.cdecl, importc: "cpSpaceGetCollisionSlop".}
proc `collisionSlop=`*(space: Space; collisionSlop: Float) {.cdecl, importc: "cpSpaceSetCollisionSlop".}
  ## Amount of encouraged penetration between colliding shapes.
  ## Used to reduce oscillating contacts and keep the collision cache warm.
  ## Defaults to 0.1. If you have poor simulation quality,
  ## increase this number as much as possible without allowing visible amounts of overlap.

proc collisionBias*(space: Space): Float {.cdecl, importc: "cpSpaceGetCollisionBias".}
proc `collisionBias=`*(space: Space; collisionBias: Float) {.cdecl, importc: "cpSpaceSetCollisionBias".}
  ## Determines how fast overlapping shapes are pushed apart.
  ## Expressed as a fraction of the error remaining after each second.
  ## Defaults to pow(1.0 - 0.1, 60.0) meaning that Chipmunk fixes 10% of overlap each frame at 60Hz.

proc collisionPersistence*(space: Space): Timestamp {.cdecl, importc: "cpSpaceGetCollisionPersistence".}
proc `collisionPersistence=`*(space: Space; collisionPersistence: Timestamp) {.cdecl, importc: "cpSpaceSetCollisionPersistence".}
  ## Number of frames that contact information should persist.
  ## Defaults to 3. There is probably never a reason to change this value.

proc userData*(space: Space): DataPointer {.cdecl, importc: "cpSpaceGetUserData".}
proc `userData=`*(space: Space; userData: DataPointer) {.cdecl, importc: "cpSpaceSetUserData".}
  ## User definable data pointer.
  ## Generally this points to your game's controller or game state
  ## class so you can access it when given a cpSpace reference in a callback.

proc staticBody*(space: Space): Body {.cdecl, importc: "cpSpaceGetStaticBody".}
  ## The Space provided static body for a given cpSpace.
  ## This is merely provided for convenience and you are not required to use it.

proc currentTimeStep*(space: Space): Float {.cdecl, importc: "cpSpaceGetCurrentTimeStep".}
  ## Returns the current (or most recent) time step used with the given space.
  ## Useful from callbacks if your time step is not a compile-time global.

proc isLocked*(space: Space): bool {.cdecl, importc: "cpSpaceIsLocked".}
  ## returns true from inside a callback when objects cannot be added/removed.

proc addDefaultCollisionHandler*(space: Space): ptr CollisionHandler {.cdecl, importc: "cpSpaceAddDefaultCollisionHandler".}
  ## Create or return the existing collision handler that is called for all collisions that are not handled by a more specific collision handler.

proc addCollisionHandler*(space: Space; a: CollisionType; b: CollisionType): ptr CollisionHandler {.cdecl, importc: "cpSpaceAddCollisionHandler".}
  ## Create or return the existing collision handler for the specified pair of collision types.
  ## If wildcard handlers are used with either of the collision types, it's the responibility of the custom handler to invoke the wildcard handlers.

proc addWildcardHandler*(space: Space; `type`: CollisionType): ptr CollisionHandler {.cdecl, importc: "cpSpaceAddWildcardHandler".}
  ## Create or return the existing wildcard collision handler for the specified type.

proc addShape*(space: Space; shape: Shape): Shape {.cdecl, importc: "cpSpaceAddShape".}
  ## Add a collision shape to the simulation.
  ## If the shape is attached to a static body, it will be added as a static shape.

proc addBody*(space: Space; body: Body): Body {.cdecl, importc: "cpSpaceAddBody".}
  ## Add a rigid body to the simulation.

proc addConstraint*(space: Space; constraint: Constraint): Constraint {.cdecl, importc: "cpSpaceAddConstraint".}
  ## Add a constraint to the simulation.

proc removeShape*(space: Space; shape: Shape) {.cdecl, importc: "cpSpaceRemoveShape".}
  ## Remove a collision shape from the simulation.

proc removeBody*(space: Space; body: Body) {.cdecl, importc: "cpSpaceRemoveBody".}
  ## Remove a rigid body from the simulation.

proc removeConstraint*(space: Space; constraint: Constraint) {.cdecl, importc: "cpSpaceRemoveConstraint".}
  ## Remove a constraint from the simulation.

proc containsShape*(space: Space; shape: Shape): bool {.cdecl, importc: "cpSpaceContainsShape".}
  ## Test if a collision shape has been added to the space.

proc containsBody*(space: Space; body: Body): bool {.cdecl, importc: "cpSpaceContainsBody".}
  ## Test if a rigid body has been added to the space.

proc containsConstraint*(space: Space; constraint: Constraint): bool {.cdecl, importc: "cpSpaceContainsConstraint".}
  ## Test if a constraint has been added to the space.

proc addPostStepCallback*(space: Space; `func`: PostStepFunc; key: pointer; data: pointer): bool {.cdecl, importc: "cpSpaceAddPostStepCallback".}
  ## Schedule a post-step callback to be called when cpSpaceStep() finishes.
  ## You can only register one callback per unique value for `key`.
  ## Returns true only if `key` has never been scheduled before.
  ## It's possible to pass `NULL` for `func` if you only want to mark `key` as being used.

proc pointQuery*(space: Space; point: Vect; maxDistance: Float; filter: ShapeFilter; `func`: SpacePointQueryFunc; data: pointer) {.cdecl, importc: "cpSpacePointQuery".}
  ## Query the space at a point and call `func` for each shape found.

proc pointQueryNearest*(space: Space; point: Vect; maxDistance: Float; filter: ShapeFilter; `out`: ptr PointQueryInfo): Shape {.cdecl, importc: "cpSpacePointQueryNearest".}
  ## Query the space at a point and return the nearest shape found. Returns NULL if no shapes were found.

proc segmentQuery*(space: Space; start: Vect; `end`: Vect; radius: Float; filter: ShapeFilter; `func`: SpaceSegmentQueryFunc; data: pointer) {.cdecl, importc: "cpSpaceSegmentQuery".}
  ## Perform a directed line segment query (like a raycast) against the space calling `func` for each shape intersected.

proc segmentQueryFirst*(space: Space; start: Vect; `end`: Vect; radius: Float; filter: ShapeFilter; `out`: ptr SegmentQueryInfo): Shape {.cdecl, importc: "cpSpaceSegmentQueryFirst".}
  ## Perform a directed line segment query (like a raycast) against the space and return the first shape hit. Returns NULL if no shapes were hit.

proc bBQuery*(space: Space; bb: BB; filter: ShapeFilter; `func`: SpaceBBQueryFunc; data: pointer) {.cdecl, importc: "cpSpaceBBQuery".}
  ## Perform a fast rectangle query on the space calling `func` for each shape found.
  ## Only the shape's bounding boxes are checked for overlap, not their full shape.

proc shapeQuery*(space: Space; shape: Shape; `func`: SpaceShapeQueryFunc; data: pointer): bool {.cdecl, importc: "cpSpaceShapeQuery".}
  ## Query a space for any shapes overlapping the given shape and call `func` for each shape found.

proc eachBody*(space: Space; `func`: SpaceBodyIteratorFunc; data: pointer) {.cdecl, importc: "cpSpaceEachBody".}
  ## Call `func` for each body in the space.

proc eachShape*(space: Space; `func`: SpaceShapeIteratorFunc; data: pointer) {.cdecl, importc: "cpSpaceEachShape".}
  ## Call `func` for each shape in the space.

proc eachConstraint*(space: Space; `func`: SpaceConstraintIteratorFunc; data: pointer) {.cdecl, importc: "cpSpaceEachConstraint".}
  ## Call `func` for each shape in the space.

proc reindexStatic*(space: Space) {.cdecl, importc: "cpSpaceReindexStatic".}
  ## Update the collision detection info for the static shapes in the space.

proc reindexShape*(space: Space; shape: Shape) {.cdecl, importc: "cpSpaceReindexShape".}
  ## Update the collision detection data for a specific shape in the space.

proc reindexShapesForBody*(space: Space; body: Body) {.cdecl, importc: "cpSpaceReindexShapesForBody".}
  ## Update the collision detection data for all shapes attached to a body.

proc useSpatialHash*(space: Space; dim: Float; count: cint) {.cdecl, importc: "cpSpaceUseSpatialHash".}
  ## Switch the space to use a spatial has as it's spatial index.

proc step*(space: Space; dt: Float) {.cdecl, importc: "cpSpaceStep".}
  ## Step the space forward in time by `dt`.

proc debugDraw*(space: Space; options: ptr SpaceDebugDrawOptions) {.cdecl, importc: "cpSpaceDebugDraw".}
  ## Debug draw the current state of the space using the supplied drawing options.

var VersionString* {.importc: "cpVersionString".}: cstring
  ## Version string.

proc momentForCircle*(m: Float; r1: Float; r2: Float; offset: Vect): Float {.cdecl, importc: "cpMomentForCircle".}
  ## Calculate the moment of inertia for a circle.
  ## `r1` and `r2` are the inner and outer diameters. A solid circle has an inner diameter of 0.

proc areaForCircle*(r1: Float; r2: Float): Float {.cdecl, importc: "cpAreaForCircle".}
  ## Calculate area of a hollow circle.
  ## `r1` and `r2` are the inner and outer diameters. A solid circle has an inner diameter of 0.

proc momentForSegment*(m: Float; a: Vect; b: Vect; radius: Float): Float {.cdecl, importc: "cpMomentForSegment".}
  ## Calculate the moment of inertia for a line segment.
  ## Beveling radius is not supported.

proc areaForSegment*(a: Vect; b: Vect; radius: Float): Float {.cdecl, importc: "cpAreaForSegment".}
  ## Calculate the area of a fattened (capsule shaped) line segment.

proc momentForPoly*(m: Float; count: cint; verts: ptr Vect; offset: Vect; radius: Float): Float {.cdecl, importc: "cpMomentForPoly".}
  ## Calculate the moment of inertia for a solid polygon shape assuming it's center of gravity is at it's centroid. The offset is added to each vertex.

proc areaForPoly*(count: cint; verts: ptr Vect; radius: Float): Float {.cdecl, importc: "cpAreaForPoly".}
  ## Calculate the signed area of a polygon. A Clockwise winding gives positive area.
  ## This is probably backwards from what you expect, but matches Chipmunk's the winding for poly shapes.

proc centroidForPoly*(count: cint; verts: ptr Vect): Vect {.cdecl, importc: "cpCentroidForPoly".}
  ## Calculate the natural centroid of a polygon.

proc momentForBox*(m: Float; width: Float; height: Float): Float {.cdecl, importc: "cpMomentForBox".}
  ## Calculate the moment of inertia for a solid box.

proc momentForBox*(m: Float; box: BB): Float {.cdecl, importc: "cpMomentForBox2".}
  ## Calculate the moment of inertia for a solid box.

proc convexHull*(count: cint; verts: ptr Vect; result: ptr Vect; first: ptr cint; tol: Float): cint {.cdecl, importc: "cpConvexHull".}
  ## Calculate the convex hull of a given set of points. Returns the count of points in the hull.
  ## `result` must be a pointer to a `cpVect` array with at least `count` elements. If `verts` == `result`, then `verts` will be reduced inplace.
  ## `first` is an optional pointer to an integer to store where the first vertex in the hull came from (i.e. verts[first] == result[0])
  ## `tol` is the allowed amount to shrink the hull when simplifying it. A tolerance of 0.0 creates an exact hull.

proc closestPointOnSegment*(p: Vect; a: Vect; b: Vect): Vect {.inline, cdecl.} =
  ## Returns the closest point on the line segment ab, to the point p.
  var delta: Vect = vsub(a, b)
  var t: Float = fclamp01(vdot(delta, vsub(p, b)) div
      vlengthsq(delta))
  return vadd(b, vmult(delta, t))



# Nino: disable * because it clashes with DriveDirection
# proc `*`*(v: Vect; s: Float): Vect = vmult(v, s)
proc `+`*(v1, v2: Vect): Vect = vadd(v1, v2)
proc `-`*(v1, v2: Vect): Vect = vsub(v1, v2)
proc `==`*(v1, v2: Vect): bool = veql(v1, v2)
proc `-`*(v: Vect): Vect = vneg(v)


proc `|`*(a, b: SpaceDebugDrawFlags): SpaceDebugDrawFlags =
  ## Combines multiple flags as a bitmask
  cast[SpaceDebugDrawFlags](cint(a) or cint(b))

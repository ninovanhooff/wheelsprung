import std/math
import chipmunk7
import strutils
import playdate/api


var gravity = v(0, 100)
var timeStep = 1.0/50.0
var time = 0.0

var space = newSpace()
space.gravity = gravity
# space.iterations = 1

proc addWheel(space: Space, pos: Vect): Body =
  var radius = 15.0f
  var mass = 1.0f

  var moment = momentForCircle(mass, 0, radius, vzero)

  var body = space.addBody(newBody(mass, moment))
  body.position = pos

  var shape = space.addShape(newCircleShape(body, radius, vzero))
  shape.friction = 1.0f

  return body

proc addChassis(space: Space, pos: Vect): Body =
  var mass = 5.0f
  var width = 80.0f
  var height = 30.0f

  var moment = momentForBox(mass, width, height)

  var body = space.addBody(newBody(mass, moment))
  body.position = pos

  var shape = space.addShape(newBoxShape(body, width, height, 0f))
  shape.elasticity = 0.0f
  shape.friction = 0.7f

  return body

proc rad2deg(rad: float): float =
  return rad * 180.0 / PI

proc updateChipmunkHello*() {.cdecl, raises: [].} =
  space.step(timeStep)
  time += timeStep

proc drawCircle(pos: Vect, radius: float, angle:float, color: LCDColor) =
  # covert from center position to top left
  let x = (pos.x - radius).toInt
  let y = (pos.y - radius).toInt
  let size: int = (radius * 2f).toInt
  # angle is in radians, convert to degrees
  let deg = rad2deg(angle)
  playdate.graphics.drawEllipse(x,y,size, size, 1, deg, deg + 350, color);

proc drawSegment(segment: SegmentShape, color: LCDColor) =
  playdate.graphics.drawLine(segment.a.x.toInt, segment.a.y.toInt, segment.b.x.toInt, segment.b.y.toInt, 1, color);

proc shapeIter(shape: Shape, data: pointer) {.cdecl.} =
    if shape.kind == cpCircleShape:
      let circle = cast[CircleShape](shape)
      drawCircle(circle.body.position, circle.radius, circle.body.angle, kColorBlack)
    elif shape.kind == cpSegmentShape:
      let segment = cast[SegmentShape](shape)
      drawSegment(segment, kColorBlack)
    elif shape.kind == cpPolyShape:
      let poly = cast[PolyShape](shape)
      let numVerts = poly.count
      for i in 0 ..< numVerts:
        let a = localToWorld(poly.body, poly.vert(i))
        let b = localToWorld(poly.body, poly.vert((i+1) mod numVerts))
        
        try:
          playdate.system.logToConsole("ax $# ay$# bx $# by $#".format(
            a.x, a.y, b.x, b.y
          ))
        except:
          playdate.system.logToConsole("Error logging ball pos to console")


        playdate.graphics.drawLine(a.x.toInt, a.y.toInt, b.x.toInt, b.y.toInt, 1, kColorBlack);

proc drawChipmunkHello*() =
  # iterate over all shapes in the space
  eachShape(space, shapeIter, nil)

let
  posA = v(50, 60)
  posB = v(110, 60)
  posChassis = v(80, 20)


var ground = newSegmentShape(space.staticBody, v(20, 150), v(140, 170), 0)
ground.friction = 1.0
discard space.addShape(ground)

let wheel1 = addWheel(space, posA)
let wheel2 = addWheel(space, posB)
let chassis = addChassis(space, posChassis)



when defined chipmunkNoDestructors:
  ballShape.destroy()
  ballBody.destroy()
  ground.destroy()
  space.destroy()
import strutils
import std/math
import chipmunk7
import playdate/api



var gravity = v(0, 100)

var space = newSpace()
space.gravity = gravity

var ground = newSegmentShape(space.staticBody, v(80, 50), v(140, 60), 0)
ground.friction = 1.0
discard space.addShape(ground)

var radius = 10.0
var mass = 2.0

var moment = momentForCircle(mass, 0, radius, vzero)

var ballBody = space.addBody(newBody(mass, moment))
ballBody.position = v(100, 0)

var ballShape = space.addShape(newCircleShape(ballBody, radius, vzero))
ballShape.friction = 0.7

var timeStep = 1.0/50.0

var time = 0.0

proc rad2deg(rad: float): float =
  return rad * 180.0 / PI

proc updateChipmunkHello*() {.cdecl, raises: [].} =
  let pos = ballBody.position
  let vel = ballBody.velocity
  let angle = ballBody.angle
  try:
    playdate.system.logToConsole("Time is $#. ballBody is at ($#, $#). Its velocity is ($#, $#). Its angle is $#".format(
      time, pos.x, pos.y, vel.x, vel.y, angle
    ))
  except:
    playdate.system.logToConsole("Error logging ball pos to console")

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

proc drawChipmunkHello*() =
  var pos = ballBody.position
  var rot = ballBody.angle

  drawCircle(pos, radius, rot, kColorBlack)
  drawSegment(ground, kColorBlack)

when defined chipmunkNoDestructors:
  ballShape.destroy()
  ballBody.destroy()
  ground.destroy()
  space.destroy()
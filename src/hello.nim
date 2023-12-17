import strutils
import chipmunk7
import playdate/api



var gravity = v(0, -100)

var space = newSpace()
space.gravity = gravity

var ground = newSegmentShape(space.staticBody, v(-20, 5), v(20, -5), 0)
ground.friction = 1.0
var discarded = space.addShape(ground)

var radius = 5.0
var mass = 1.0

var moment = momentForCircle(mass, 0, radius, vzero)

var ballBody = space.addBody(newBody(mass, moment))
ballBody.position = v(0, 15)

var ballShape = space.addShape(newCircleShape(ballBody, radius, vzero))
ballShape.friction = 0.7

var timeStep = 1.0/60.0

var time = 0.0

proc updateChipmunkHello*() {.cdecl, raises: [].} =
  var pos = ballBody.position
  var vel = ballBody.velocity
  try:
    playdate.system.logToConsole("Time is $#. ballBody is at ($#, $#). Its velocity is ($#, $#)".format(
      time, pos.x, pos.y, vel.x, vel.y
    ))
  except:
    playdate.system.logToConsole("Error logging ball pos to console")

  space.step(timeStep)

  time += timeStep


proc drawCircle(pos: Vect, radius: float, angle:float, color: LCDColor) =
  playdate.graphics.drawEllipse(pos.x.toInt, -pos.y.toInt, radius.toInt, radius.toInt, 2, angle, angle + 355, color);

proc drawSegment(segment: SegmentShape, color: LCDColor) =
  playdate.graphics.drawLine(segment.a.x.toInt, -segment.a.y.toInt, segment.b.x.toInt, -segment.b.y.toInt, 1, color);

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
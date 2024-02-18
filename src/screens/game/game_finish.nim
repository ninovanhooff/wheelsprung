import chipmunk7
import graphics_utils
import game_types

const
  vFinishSize = v(38.0, 38.0) # half of the finish image size

proc addFinish*(space: Space, finish: Finish) =
  let vFinish = finish.toVect
  let bb = BB(
    l: vFinish.x, b: vFinish.y + vFinishSize.y, 
    r: vFinish.x + vFinishSize.x, t: vFinish.y
  )
  let shape = space.addShape(space.staticBody.newBoxShape(bb, 0.0))
  shape.filter = GameShapeFilters.Finish
  shape.collisionType = GameCollisionTypes.Finish

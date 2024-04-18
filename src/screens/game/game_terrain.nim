import chipmunk7
import game_types, graphics_types
import graphics_utils
import std/sequtils

const
  terrainFriction = 10.0

proc addTerrain*(space: Space, terrainSegments: seq[Polygon | Polyline]) =
  # Add the polygons as segment shapes to the physics space
  for obj in terrainSegments:
    let radius = when obj is Polygon: 0.0f
      elif obj is Polyline: obj.thickness / 2f
    let vects: seq[Vect] = obj.vertices.map(toVect)
    for i in 1..vects.high:
      let shape = newSegmentShape(space.staticBody, vects[i-1], vects[i], radius)
      shape.filter = GameShapeFilters.Terrain
      shape.collisionType = GameCollisionTypes.Terrain
      shape.friction = terrainFriction
      discard space.addShape(shape)

import chipmunk7
import game_types, graphics_types
import graphics_utils
import std/sequtils

const
  terrainFriction = 10.0

proc addTerrain*(space: Space, terrainPolygons: seq[Polygon]) = #todo change type to seq[Vertex]
  # Add the polygons as segment shapes to the physics space
  for polygon in terrainPolygons:
    let vects: seq[Vect] = polygon.vertices.map(toVect)
    for i in 1..vects.high:
      let shape = newSegmentShape(space.staticBody, vects[i-1], vects[i], 0.0)
      shape.filter = GameShapeFilters.Terrain
      shape.collisionType = GameCollisionTypes.Terrain
      shape.friction = terrainFriction
      discard space.addShape(shape)
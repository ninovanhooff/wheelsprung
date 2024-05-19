function polygonArea(vertices) { 
  var area = 0;
  var j = 0;
  for (var i = 0; i < vertices.length; i++) {
      j = (i + 1) % vertices.length;
      area += vertices[i].x * vertices[j].y;
      area -= vertices[j].x * vertices[i].y;
  }
  return area / 2;
}

export function ensureWindingOrder(vertices) {
  var clockwise = polygonArea(vertices) > 0;
  if (clockwise) {
      tiled.log("Reversing clockwise polygon:" + vertices);
      vertices.reverse();
  }
  return vertices;
}
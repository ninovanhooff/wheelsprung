export function newPolygon(oldObj) {
  var object = new MapObject();
  object.x = oldObj.x;
  object.y = oldObj.y;
  object.width = oldObj.width;
  object.height = oldObj.height;
  object.shape = MapObject.Polygon;
  return object;
}

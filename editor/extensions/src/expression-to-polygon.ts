// make these available to the eval'd expression
let cos = Math.cos;
let sin = Math.sin;

export function genPolyline({ 
  posX, posY, 
  startT = 0,
  endT = startT + 100, 
  expressionX = "t", expressionY, 
  objectName = undefined, 
  epsilon = 0.5 
}: { posX: number, posY: number, endT?: number, startT: number, expressionX?: string, expressionY: string, objectName?: string, epsilon?: number }) {
  if (!tiled.activeAsset.isTileMap) {
    tiled.log("No active layer selected");
    return;
  }
  let activeAsset: TileMap = tiled.activeAsset as TileMap;
  var currentLayer = activeAsset.currentLayer as ObjectGroup;
  if (!currentLayer || !currentLayer.isObjectLayer) {
    tiled.log("No active layer selected, or not an object layer");
    return;
  }
  let resultsX = evaluateExpression(expressionX, startT, endT);
  let resultsY = evaluateExpression(expressionY, startT, endT);
  let points: point[] = resultsX.map((x, i) => ({ x, y: resultsY[i] }));
  let polyline = new MapObject();
  polyline.x = posX;
  polyline.y = posY;
  polyline.shape = MapObject.Polyline;
  polyline.polygon = optimizePoints(points, epsilon);
  if (objectName) {
    removeObjectWithName(objectName, currentLayer);
    polyline.name = objectName;
  }
  tiled.log("Optimized polygon: " + polyline.polygon.length);
  currentLayer.addObject(polyline);
}

function removeObjectWithName(name: string, layer: ObjectGroup) {
  let existingObject = layer.objects.find(obj => obj.name === name);
  if (existingObject) {
    tiled.log("Removing existing object with name: " + name);
    layer.removeObject(existingObject);
  }
}

function evaluateExpression(expression: string, startT:number = 0, endT: number): number[] {
  tiled.log("Evaluating expression: " + expression);
  const sanitizedExpression = expression.replace(/[^-()\d/*+.\w\^]/g, '');
  tiled.log("Sanitized expression: " + sanitizedExpression);
  return Array.from({ length: endT - startT }, (_, i) => {
    let t = startT + i;
    let replacedExpression = eval(sanitizedExpression.replace("t", t.toString()));
    let result = eval(replacedExpression);
    return result;
  });
}

/**
 * Optimizes the points by removing straight lines using the Ramer-Douglas-Peucker algorithm
 * @param points 
 * @returns 
 */
function optimizePoints(points: point[], epsilon: number = 0.5): point[] {
  if (points.length < 3) {
    return points;
  }
  var dMax = 0.0;
  let dMaxIndex = 0;
  for (let i = 1; i < points.length - 1; i++) {
    let d = perpendicularDistance(points[i], points[0], points[points.length - 1]);
    if (d > dMax) {
      dMax = d;
      dMaxIndex = i;
    }
  }
  if (dMax > epsilon) {
    const left = optimizePoints(points.slice(0, dMaxIndex + 1), epsilon);
    const right = optimizePoints(points.slice(dMaxIndex), epsilon);
    return left.slice(0, -1).concat(right);
  } else {
    return [points[0], points[points.length - 1]];
  }
}

function perpendicularDistance(arg0: point, arg1: point, arg2: point) {
  const { x: x1, y: y1 } = arg1;
  const { x: x2, y: y2 } = arg2;
  const { x: x0, y: y0 } = arg0;

  const numerator = Math.abs((y2 - y1) * x0 - (x2 - x1) * y0 + x2 * y1 - y2 * x1);
  const denominator = Math.sqrt((y2 - y1) ** 2 + (x2 - x1) ** 2);

  return numerator / denominator;
}

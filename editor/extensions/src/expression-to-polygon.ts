// make these available to the eval'd expression
let cos = Math.cos;
let sin = Math.sin;

function newPolyline(posX: number, posY: number, polygon: point[]) {
  var object = new MapObject();
  object.x = posX;
  object.y = posY;
  object.shape = MapObject.Polyline;
  object.polygon = polygon
  return object;
}

export function evalDemo(posX: number, posY: number, numPoints: number = 10, expressionX: string = "t", expressionY: string, epsilon: number = 0.5) {
  
  // let runnable :any = eval(result);
  // runnable.Run("RUN!").then((result:string)=>{tiled.log(result);});
  

  let resultsX = evaluateExpression(expressionX, numPoints);
  let resultsY = evaluateExpression(expressionY, numPoints);
  let points: point[] = resultsX.map((x, i) => ({ x, y: resultsY[i] }));
  let polygon = newPolyline(posX, posY, optimizePoints(points, epsilon));
  tiled.log("Optimized polygon: " + polygon.polygon.length);
  this.activeAsset.currentLayer.addObject(polygon);
}

function evaluateExpression(expression: string, numPoints: number): number[] {
  tiled.log("Evaluating expression: " + expression);
  const sanitizedExpression = expression.replace(/[^-()\d/*+.\w\^]/g, '');
  tiled.log("Sanitized expression: " + sanitizedExpression);
  return Array.from({ length: numPoints }, (_, i) => {
    let t = i;
    let replacedExpression = eval(sanitizedExpression.replace("t", t.toString()));
    let result = eval(replacedExpression);
    tiled.log(result);
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

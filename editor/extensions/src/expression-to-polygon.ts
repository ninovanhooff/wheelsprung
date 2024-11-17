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

export function evalDemo(posX: number, posY: number, resolution: number = 10, expressionX: string = "t", expressionY: string) {
  
  // let runnable :any = eval(result);
  // runnable.Run("RUN!").then((result:string)=>{tiled.log(result);});
  

  let resultsX = evaluateExpression(expressionX, resolution);
  let resultsY = evaluateExpression(expressionY, resolution);
  let points: point[] = resultsX.map((x, i) => ({ x, y: resultsY[i] }));
  let polygon = newPolyline(posX, posY, points);
  this.activeAsset.currentLayer.addObject(polygon);
}

function evaluateExpression(expression: string, resolution: number): number[] {
  tiled.log("Evaluating expression: " + expression);
  const sanitizedExpression = expression.replace(/[^-()\d/*+.\w\^]/g, '');
  // if (sanitizedExpression !== expression) {
    tiled.log("Sanitized expression: " + sanitizedExpression);
  // }
  return Array.from({ length: resolution }, (_, i) => {
    let t = i;
    let replacedExpression = eval(sanitizedExpression.replace("t", t.toString()));
    let result = eval(replacedExpression);
    tiled.log(result);
    return result;
  });
}
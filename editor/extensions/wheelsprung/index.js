(() => {
  // src/ensure-winding-order.ts
  function polygonArea(vertices) {
    var area = 0;
    var j = 0;
    for (var i2 = 0; i2 < vertices.length; i2++) {
      j = (i2 + 1) % vertices.length;
      area += vertices[i2].x * vertices[j].y;
      area -= vertices[j].x * vertices[i2].y;
    }
    return area / 2;
  }
  function ensureWindingOrder(vertices) {
    var clockwise = polygonArea(vertices) > 0;
    if (clockwise) {
      tiled.log("Reversing clockwise polygon:" + vertices);
      vertices.reverse();
    }
    return vertices;
  }

  // src/apply-wheelsprung-fixes.ts
  function applyWheelsprungFixes(mapOrLayer) {
    tiled.log("Running applyWheelsprungFixes:" + mapOrLayer);
    if (!mapOrLayer) {
      return;
    }
    ;
    if (mapOrLayer.isObjectLayer) {
      let objects = mapOrLayer.objects;
      for (let object of objects) {
        object.x = Math.round(object.x);
        object.y = Math.round(object.y);
        object.width = Math.round(object.width);
        object.height = Math.round(object.height);
        if (object.shape == MapObject.Polygon || object.shape == MapObject.Polyline) {
          object.polygon = object.polygon.map(
            (p) => Qt.point(
              Math.round(p.x),
              Math.round(p.y)
            )
          );
          object.polygon = ensureWindingOrder(object.polygon);
        }
        if (object.shape == MapObject.Ellipse && object.className == "DynamicObject") {
          if (object.width != object.height) {
            tiled.log("Ellipses not supported for Dynamic Objects. Making circular:" + object);
          }
          if (object.height <= 0) {
            tiled.log("Circle height must be positive. Setting to 20.0:" + object);
            object.height = 20;
          }
          object.height = object.width;
        }
      }
    } else if (mapOrLayer.isTileMap || mapOrLayer.isGroupLayer) {
      let numLayers = mapOrLayer.layerCount;
      for (var i2 = 0; i2 < numLayers; i2++) {
        applyWheelsprungFixes(mapOrLayer.layerAt(i2));
      }
    } else {
    }
  }

  // src/expression-to-polygon.ts
  var cos = Math.cos;
  var sin = Math.sin;
  function genPolyline(posX, posY, numPoints2 = 10, expressionX = "t", expressionY, epsilon = 0.5, name = void 0) {
    if (tiled.activeAsset.isTileMap == false) {
      tiled.log("No active layer selected");
      return;
    }
    let activeAsset = tiled.activeAsset;
    var currentLayer = activeAsset.currentLayer;
    if (currentLayer == void 0 || currentLayer.isObjectLayer == false) {
      tiled.log("No active layer selected, or not an object layer");
      return;
    }
    let resultsX = evaluateExpression(expressionX, numPoints2);
    let resultsY = evaluateExpression(expressionY, numPoints2);
    let points = resultsX.map((x, i2) => ({ x, y: resultsY[i2] }));
    let polyline = new MapObject();
    polyline.x = posX;
    polyline.y = posY;
    polyline.shape = MapObject.Polyline;
    polyline.polygon = optimizePoints(points, epsilon);
    if (name != "" && name != void 0) {
      removeObjectWithName(name, currentLayer);
      polyline.name = name;
    }
    tiled.log("Optimized polygon: " + polyline.polygon.length);
    currentLayer.addObject(polyline);
  }
  function removeObjectWithName(name, layer) {
    let existingObject = layer.objects.find((obj) => obj.name === name);
    if (existingObject) {
      layer.removeObject(existingObject);
    }
  }
  function evaluateExpression(expression, numPoints) {
    tiled.log("Evaluating expression: " + expression);
    const sanitizedExpression = expression.replace(/[^-()\d/*+.\w\^]/g, "");
    tiled.log("Sanitized expression: " + sanitizedExpression);
    return Array.from({ length: numPoints }, (_, i) => {
      let t = i;
      let replacedExpression = eval(sanitizedExpression.replace("t", t.toString()));
      let result = eval(replacedExpression);
      tiled.log(result);
      return result;
    });
  }
  function optimizePoints(points, epsilon = 0.5) {
    if (points.length < 3) {
      return points;
    }
    var dMax = 0;
    let dMaxIndex = 0;
    for (let i2 = 1; i2 < points.length - 1; i2++) {
      let d = perpendicularDistance(points[i2], points[0], points[points.length - 1]);
      if (d > dMax) {
        dMax = d;
        dMaxIndex = i2;
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
  function perpendicularDistance(arg0, arg1, arg2) {
    const { x: x1, y: y1 } = arg1;
    const { x: x2, y: y2 } = arg2;
    const { x: x0, y: y0 } = arg0;
    const numerator = Math.abs((y2 - y1) * x0 - (x2 - x1) * y0 + x2 * y1 - y2 * x1);
    const denominator = Math.sqrt((y2 - y1) ** 2 + (x2 - x1) ** 2);
    return numerator / denominator;
  }

  // src/wheelsprung-map.ts
  var mapFormat = {
    name: "wheelsprung",
    extension: "wmj",
    write: function(map, fileName) {
      tiled.mapFormatForFile("test.tmj").write(map, fileName);
      return void 0;
    },
    read: function(fileName) {
      let map = tiled.mapFormatForFile("test.tmj").read(fileName);
      return map;
    }
  };
  var wheelsprung_map_default = mapFormat;

  // src/index.ts
  tiled.registerMapFormat("wheelsprung", wheelsprung_map_default);
  tiled.assetAboutToBeSaved.connect(function(asset) {
    if (asset.isTileMap)
      applyWheelsprungFixes(asset);
  });
  var applyWheelsprungFixesAction = tiled.registerAction("ApplyWheelsprungFixes", function() {
    applyWheelsprungFixes(tiled.activeAsset);
  });
  applyWheelsprungFixesAction.text = "Apply Wheelsprung Fixes";
  tiled.extendMenu("Edit", [
    { action: "ApplyWheelsprungFixes", before: "Preferences" }
  ]);
  tiled.genPolyline = genPolyline;
})();

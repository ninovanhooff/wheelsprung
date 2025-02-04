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

  // src/outline-polyline.ts
  function getOffsets(a, b, thickness) {
    var dx = b.x - a.x, dy = b.y - a.y, len = Math.sqrt(dx * dx + dy * dy), scale = thickness / (2 * len);
    return {
      x: -scale * dy,
      y: scale * dx
    };
  }
  function getIntersection(a1, b1, a2, b2) {
    var k1 = (b1.y - a1.y) / (b1.x - a1.x), k2 = (b2.y - a2.y) / (b2.x - a2.x);
    if (Math.abs(k1 - k2) < 1e-5) {
      return;
    }
    var m1 = a1.y - k1 * a1.x;
    var m2 = a2.y - k2 * a2.x;
    var x = (m1 - m2) / (k2 - k1);
    var y = k1 * x + m1;
    return { x, y };
  }
  function isArray(obj) {
    return Object.prototype.toString.call(obj) === "[object Array]";
  }
  function me(points, thickness) {
    var arr = [];
    for (var i2 = 0; i2 < points.length; i2++) {
      var pt = points[i2];
      arr.push({
        x: pt[0],
        y: pt[1]
      });
    }
    points = arr;
    if (!isArray(thickness)) {
      var t2 = thickness;
      thickness = [];
      for (var i2 = 0; i2 < points.length; i2++) {
        thickness.push(t2);
      }
    }
    var off, off2, poly = [], isFirst, isLast, prevA, prevB, interA, interB, p0a, p1a, p0b, p1b;
    for (var i2 = 0, il = points.length - 1; i2 < il; i2++) {
      isFirst = !i2;
      isLast = i2 === points.length - 2;
      off = getOffsets(points[i2], points[i2 + 1], thickness[i2]);
      off2 = getOffsets(points[i2], points[i2 + 1], thickness[i2 + 1]);
      p0a = { x: points[i2].x + off.x, y: points[i2].y + off.y };
      p1a = { x: points[i2 + 1].x + off2.x, y: points[i2 + 1].y + off2.y };
      p0b = { x: points[i2].x - off.x, y: points[i2].y - off.y };
      p1b = { x: points[i2 + 1].x - off2.x, y: points[i2 + 1].y - off2.y };
      if (!isFirst) {
        interA = getIntersection(prevA[0], prevA[1], p0a, p1a);
        if (interA) {
          poly.unshift(interA);
        }
        interB = getIntersection(prevB[0], prevB[1], p0b, p1b);
        if (interB) {
          poly.push(interB);
        }
      }
      if (isFirst) {
        poly.unshift(p0a);
        poly.push(p0b);
      }
      if (isLast) {
        poly.unshift(p1a);
        poly.push(p1b);
      }
      if (!isLast) {
        prevA = [p0a, p1a];
        prevB = [p0b, p1b];
      }
    }
    for (var i2 = 0; i2 < poly.length; i2++) {
      var pt = poly[i2];
      poly[i2] = [pt.x, pt.y];
    }
    poly.push(poly[0]);
    return poly;
  }
  function polylineToPolygon(polygon, thickness) {
    var points = polygon.map((pt) => [pt.x, pt.y]);
    tiled.log("Running me:" + points);
    var vertices = me(points, thickness);
    return vertices.map((pt) => Qt.point(pt[0], pt[1]));
  }

  // src/new-polygon.ts
  function newPolygon(oldObj) {
    var object = new MapObject();
    object.x = oldObj.x;
    object.y = oldObj.y;
    object.width = oldObj.width;
    object.height = oldObj.height;
    object.shape = MapObject.Polygon;
    return object;
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
        if (object.shape == MapObject.Polyline && object.selected) {
          var polygon = polylineToPolygon(object.polygon, 4);
          var newObject = newPolygon(object);
          tiled.log("New object:" + newObject);
          tiled.log("new polygon:" + polygon);
          newObject.polygon = polygon;
          mapOrLayer.addObject(newObject);
        }
        ;
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
  function genPolyline({
    posX,
    posY,
    startT: startT2 = 0,
    endT: endT2 = startT2 + 100,
    expressionX = "t",
    expressionY,
    objectName = void 0,
    epsilon = 0.5
  }) {
    if (!tiled.activeAsset.isTileMap) {
      tiled.log("No active layer selected");
      return;
    }
    let activeAsset = tiled.activeAsset;
    var currentLayer = activeAsset.currentLayer;
    if (!currentLayer || !currentLayer.isObjectLayer) {
      tiled.log("No active layer selected, or not an object layer");
      return;
    }
    let resultsX = evaluateExpression(expressionX, startT2, endT2);
    let resultsY = evaluateExpression(expressionY, startT2, endT2);
    let points = resultsX.map((x, i2) => ({ x, y: resultsY[i2] }));
    let polyline = getOrCreateObjectWithName(objectName, currentLayer);
    polyline.x = posX;
    polyline.y = posY;
    polyline.shape = MapObject.Polyline;
    polyline.polygon = optimizePoints(points, epsilon);
    tiled.log("Optimized polygon: " + polyline.polygon.length);
    if (!polyline.layer) {
      currentLayer.addObject(polyline);
    }
  }
  function getOrCreateObjectWithName(name, layer) {
    let existingObject = layer.objects.find((obj) => obj.name === name);
    if (existingObject) {
      return existingObject;
    } else {
      return new MapObject(name);
    }
  }
  function evaluateExpression(expression, startT = 0, endT) {
    tiled.log("Evaluating expression: " + expression);
    const sanitizedExpression = expression.replace(/[^-()\d/*+.\w\^]/g, "");
    tiled.log("Sanitized expression: " + sanitizedExpression);
    return Array.from({ length: endT - startT }, (_, i) => {
      let t = startT + i;
      let replacedExpression = eval(sanitizedExpression.replace("t", t.toString()));
      let result = eval(replacedExpression);
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

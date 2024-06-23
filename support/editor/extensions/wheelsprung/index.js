(() => {
  // src/ensure-winding-order.ts
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
      for (var i = 0; i < numLayers; i++) {
        applyWheelsprungFixes(mapOrLayer.layerAt(i));
      }
    } else {
    }
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
      const file = new TextFile(fileName, TextFile.ReadOnly);
      const mapJson = file.readAll();
      file.close();
      return JSON.parse(mapJson);
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
})();

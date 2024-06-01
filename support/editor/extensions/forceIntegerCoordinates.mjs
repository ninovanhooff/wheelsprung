import { ensureWindingOrder } from "./ensureWindingOrder.mjs";

function forceIntegerCoordinates(mapOrLayer) {
	tiled.log("Running forceIntegerCoordinates:" + mapOrLayer);
	if(!mapOrLayer){
		return;
	};
	if(mapOrLayer.isObjectLayer) {
		let objects = mapOrLayer.objects;
		for(let object of objects) {
			object.x = Math.round(object.x);
			object.y = Math.round(object.y);
			object.width = Math.round(object.width);
			object.height = Math.round(object.height);
			if(object.shape == MapObject.Polygon || object.shape == MapObject.Polyline) {
				object.polygon = object.polygon.map((p) => 
					Qt.point(
						Math.round(p.x), 
						Math.round(p.y)
					)
				);
				object.polygon = ensureWindingOrder(object.polygon);
			}
			if(object.shape == MapObject.Ellipse && object.className == "DynamicObject") {
				// force circle
				object.height = object.width;
			}
		}
	} else if(mapOrLayer.isTileMap || mapOrLayer.isGroupLayer) {
		let numLayers = mapOrLayer.layerCount;
		for(var i = 0; i < numLayers; i++) {
			forceIntegerCoordinates(mapOrLayer.layerAt(i));
		}
	} else {
		//else, do nothing
	}
		
}

//Auto-apply on save:
tiled.assetAboutToBeSaved.connect(function(asset) {if(asset.isTileMap) forceIntegerCoordinates(asset); } );

//Allow manually applying via an Action:
let forceIntegerCoordinatesAction = tiled.registerAction("ForceIntegerCoordinates", function() { forceIntegerCoordinates(tiled.activeAsset); } );
forceIntegerCoordinatesAction.text = "Force Integer Coordinates";
//add this action to the Edit menu:
tiled.extendMenu("Edit", [
	{ action: "ForceIntegerCoordinates", before: "Preferences" }
]);
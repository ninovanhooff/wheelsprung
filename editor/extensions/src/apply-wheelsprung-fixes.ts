/// <reference types="@mapeditor/tiled-api" />

import { ensureWindingOrder } from "./ensure-winding-order";
import { polylineToPolygon } from "./outline-polyline";
import { newPolygon } from "./new-polygon";


export function applyWheelsprungFixes(mapOrLayer) {
	tiled.log("Running applyWheelsprungFixes:" + mapOrLayer);
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

			if (object.shape == MapObject.Polyline && object.selected) {
				var polygon = polylineToPolygon(object.polygon, 4.0);
				var newObject = newPolygon(object);
				tiled.log("New object:" + newObject);
				tiled.log("new polygon:" + polygon);
				newObject.polygon = polygon;
				mapOrLayer.addObject(newObject);
			};

			if(object.shape == MapObject.Ellipse && object.className == "DynamicObject") {
				if(object.width != object.height) {
					tiled.log("Ellipses not supported for Dynamic Objects. Making circular:" + object);
				}
				// force circle
				if(object.height <= 0.0){
					tiled.log("Circle height must be positive. Setting to 20.0:" + object);
					object.height = 20.0;
				}
				object.height = object.width;
				
			}
		}
	} else if(mapOrLayer.isTileMap || mapOrLayer.isGroupLayer) {
		let numLayers = mapOrLayer.layerCount;
		for(var i = 0; i < numLayers; i++) {
			applyWheelsprungFixes(mapOrLayer.layerAt(i));
		}
	} else {
		//else, do nothing
	}
		
}
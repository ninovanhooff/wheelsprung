import { applyWheelsprungFixes } from "./apply-wheelsprung-fixes";
import { evalDemo } from "./expression-to-polygon";
import mapFormat from "./wheelsprung-map";
export { applyWheelsprungFixes, evalDemo, mapFormat };

tiled.registerMapFormat("wheelsprung", mapFormat);

//Auto-apply on save:
tiled.assetAboutToBeSaved.connect(function(asset) {if(asset.isTileMap) applyWheelsprungFixes(asset); } );

//Allow manually applying via an Action:
let applyWheelsprungFixesAction = tiled.registerAction("ApplyWheelsprungFixes", function() { applyWheelsprungFixes(tiled.activeAsset); } );
applyWheelsprungFixesAction.text = "Apply Wheelsprung Fixes";
//add this action to the Edit menu:
tiled.extendMenu("Edit", [
	{ action: "ApplyWheelsprungFixes", before: "Preferences" }
]);

// @ts-ignore
tiled.evalDemo = evalDemo;

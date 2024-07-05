
const mapFormat: ScriptedMapFormat = {
  name: "wheelsprung",
  extension: "wmj",
  write: function(map: TileMap, fileName: string) {
    // const defaults = getProjectPropertiesDefaults();
    // const actions = JSON.stringify(tiled.actions, getCircularReplacer(), 2);
    // tiled.log(`actions: ${actions}`)
    // tiled.log(`Defaults: ${JSON.stringify(defaults, getCircularReplacer(), 2)}`);
    // printObjectGroups(map, defaults);
    
    // tiled.log(JSON.stringify(map.layers[0].className, getCircularReplacer(), 2));
    // tiled.trigger("Export");
    // const mapJson = JSON.stringify(map, null, 2);
    // const file = new TextFile(fileName, TextFile.WriteOnly);
    // file.write("hoi");
    // file.commit();

    tiled.mapFormatForFile("test.wmj").write(map, fileName);

    return undefined; // success
  },
  read: function(fileName: string): TileMap {
    const file = new TextFile(fileName, TextFile.ReadOnly);
    const mapJson = file.readAll();
    file.close();

    return JSON.parse(mapJson);
  },
};

export default mapFormat;

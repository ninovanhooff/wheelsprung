
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

    // wmj is just a tmj file with a different extension,
    // so we can use the tmj format to write the file
    tiled.mapFormatForFile("test.tmj").write(map, fileName);

    return undefined; // success
  },
  read: function(fileName: string): TileMap {
    // const file = new TextFile(fileName, TextFile.ReadOnly);
    // const mapJson = file.readAll();
    // file.close();

    // let map = JSON.parse(mapJson) as TileMap;
    // tiled.log(`Read map: ${JSON.stringify(map, null, 2)}`);
    
    let map = tiled.mapFormatForFile("test.tmj").read(fileName);
    return map;
  },
};

export default mapFormat;

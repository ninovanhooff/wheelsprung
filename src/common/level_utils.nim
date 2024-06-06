import std/options
import std/tables
import common/shared_types
import level_meta/level_data

proc nextLevelPath*(path: Path): Option[Path] = 
  var isCurrentFound = false
  for k in officialLevels.keys:
    if isCurrentFound:
      return some(k)
    if k == path:
      isCurrentFound = true
  return none(Path)


    
    
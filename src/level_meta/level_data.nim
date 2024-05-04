import tables
import sugar
import sequtils

type
  Path* = string
  LevelMeta* = ref object of RootObj
    name*: string
    path*: string
      ## path is used as id, must be unique (which it is, enforced by the file system)

proc newLevelMeta*(name: string, path: Path): LevelMeta =
  result = LevelMeta(name: name, path: path)

let levels*:  OrderedTable[Path, level_data.LevelMeta] = @[
  newLevelMeta(name = "Dragster", path = "dragster.tmj"),
  newLevelMeta(name= "Level 1", path= "level1.tmj"),
  newLevelMeta(name= "Globe of Death", path= "globe_of_death.tmj"),
  newLevelMeta(name= "Level 2", path= "level2.tmj"),
  newLevelMeta(name= "Half Pipe", path= "king_of_the_hill.tmj"),
  newLevelMeta(name= "Globe of Death 2", path= "globe_of_death_2.tmj"),
  newLevelMeta(name= "Looping", path= "looping.tmj"),
  newLevelMeta(name= "Hills", path= "hills.tmj"),
  newLevelMeta(name= "Globe of Death 3", path= "globe_of_death_3.tmj"),
  newLevelMeta(name= "Backflip", path= "backflip.tmj"),
  newLevelMeta(name= "Level 3", path= "level3.tmj"),
  newLevelMeta(name= "Hooked", path= "hooked.tmj"),
]
  .map(meta => (meta.path, meta)) # use path as key
  .toOrderedTable

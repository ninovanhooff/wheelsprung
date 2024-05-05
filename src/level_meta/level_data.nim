import tables
import sugar
import sequtils
import common/shared_types

const 
  levelsBasePath* = "levels/"

type
  LevelMeta* = ref object of RootObj
    name*: string
    path*: string
      ## path is used as id, must be unique (which it is, enforced by the file system)
      ## 

proc newLevelMeta*(name: string, path: Path): LevelMeta =
  result = LevelMeta(name: name, path: path)

let officialLevels*:  OrderedTable[Path, level_data.LevelMeta] = @[
  newLevelMeta(name = "Dragster", path="levels/dragster.tmj"),
  newLevelMeta(name= "Level 1", path="levels/level1.tmj"),
  newLevelMeta(name= "Globe of Death", path="levels/globe_of_death.tmj"),
  newLevelMeta(name= "Level 2", path="levels/level2.tmj"),
  newLevelMeta(name= "Half Pipe", path="levels/king_of_the_hill.tmj"),
  newLevelMeta(name= "Globe of Death 2", path="levels/globe_of_death_2.tmj"),
  newLevelMeta(name= "Looping", path="levels/looping.tmj"),
  newLevelMeta(name= "Hills", path="levels/hills.tmj"),
  newLevelMeta(name= "Globe of Death 3", path="levels/globe_of_death_3.tmj"),
  newLevelMeta(name= "Backflip", path="levels/backflip.tmj"),
  newLevelMeta(name= "Level 3", path="levels/level3.tmj"),
  newLevelMeta(name= "Hooked", path="levels/hooked.tmj"),
]
  .map(meta => (meta.path, meta)) # use path as key
  .toOrderedTable

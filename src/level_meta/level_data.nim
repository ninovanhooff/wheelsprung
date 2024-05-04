import tables

type 
  LevelId* = enum
    Level1, Level2, Level3, Dragster, GlobeOfDeath, GlobeOfDeath2, GlobeOfDeath3,
    HalfPipe, Looping, Hills, Backflip, Hooked, Unknown

  LevelMeta* = ref object of RootObj
    id*: LevelId
    name*: string
    path*: string

proc newLevelMeta*(id: LevelId, name: string, path: string): LevelMeta =
  result = LevelMeta(id: id, name: name, path: path)

let levels* = [
  (LevelId.Dragster, newLevelMeta(id = LevelId.Dragster, name = "Dragster", path = "dragster.tmj")),
  (LevelId.Level1, newLevelMeta(id= LevelId.Level1, name= "Level 1", path= "level1.tmj")),
  (LevelId.GlobeOfDeath, newLevelMeta(id= LevelId.GlobeOfDeath, name= "Globe of Death", path= "globe_of_death.tmj")),
  (LevelId.Level2, newLevelMeta(id= LevelId.Level2, name= "Level 2", path= "level2.tmj")),
  (LevelId.HalfPipe, newLevelMeta(id= LevelId.HalfPipe, name= "Half Pipe", path= "king_of_the_hill.tmj")),
  (LevelId.GlobeOfDeath2, newLevelMeta(id= LevelId.GlobeOfDeath2, name= "Globe of Death 2", path= "globe_of_death_2.tmj")),
  (LevelId.Looping, newLevelMeta(id= LevelId.Looping, name= "Looping", path= "looping.tmj")),
  (LevelId.Hills, newLevelMeta(id= LevelId.Hills, name= "Hills", path= "hills.tmj")),
  (LevelId.GlobeOfDeath3, newLevelMeta(id= LevelId.GlobeOfDeath3, name= "Globe of Death 3", path= "globe_of_death_3.tmj")),
  (LevelId.Backflip, newLevelMeta(id= LevelId.Backflip, name= "Backflip", path= "backflip.tmj")),
  (LevelId.Level3, newLevelMeta(id= LevelId.Level3, name= "Level 3", path= "level3.tmj")),
  (LevelId.Hooked, newLevelMeta(id= LevelId.Hooked, name= "Hooked", path= "hooked.tmj")),
].toOrderedTable()

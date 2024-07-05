import tables
import sugar
import sequtils
import common/shared_types

const 
  levelsBasePath* = "levels/"
  levelFileExtension* = ".wmj"

type
  LevelMeta* = ref object of RootObj
    name*: string
    path*: string
      ## path is used as id, must be unique (which it is, enforced by the file system)
      ## 

proc newLevelMeta*(name: string, path: Path): LevelMeta =
  result = LevelMeta(name: name, path: path)

let officialLevels*:  OrderedTable[Path, level_data.LevelMeta] = @[
  newLevelMeta(name= "Tutorial: Accelerate", path="levels/dragster.wmj"),
  newLevelMeta(name= "Tutorial: Brake", path="levels/tutorial_brake.wmj"),
  newLevelMeta(name= "Tutorial: Balance", path="levels/tutorial_leaning.wmj"),
  newLevelMeta(name= "Tutorial: Turn Around", path="levels/tutorial_turn_around.wmj"),
  newLevelMeta(name= "Globe of Death", path="levels/globe_of_death.wmj"),
  newLevelMeta(name= "Looping", path="levels/looping.wmj"),
  newLevelMeta(name= "Half Pipe", path="levels/king_of_the_hill.wmj"),
  newLevelMeta(name= "Hills", path="levels/hills.wmj"),
  newLevelMeta(name= "Globe of Death 3", path="levels/globe_of_death_3.wmj"),
  newLevelMeta(name= "Tutorial: Gravity", path="levels/tutorial_gravity.wmj"),
  newLevelMeta(name= "Gravity Vault", path="levels/gravity_vault.wmj"),
  newLevelMeta(name= "Marble Vault", path="levels/marble_vault.wmj"),
  newLevelMeta(name= "Leg Up", path="levels/leg_up.wmj"),
  newLevelMeta(name= "Backflip", path="levels/backflip.wmj"),
  newLevelMeta(name= "Killveyor", path="levels/killveyor.wmj"),
  newLevelMeta(name= "Hooked", path="levels/hooked.wmj"),
  newLevelMeta(name= "Return to sender", path="levels/return_to_sender.wmj"),
  newLevelMeta(name= "Globe of Death 2", path="levels/globe_of_death_2.wmj"),
  newLevelMeta(name= "Level 1", path="levels/level1.wmj"),
  newLevelMeta(name= "Level 2", path="levels/level2.wmj"),
  newLevelMeta(name= "Level 3", path="levels/level3.wmj"),
]
  .map(meta => (meta.path, meta)) # use path as key
  .toOrderedTable

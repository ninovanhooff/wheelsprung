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
    contentHash*: string

proc newLevelMeta*(name: string, path: Path, hash: string): LevelMeta =
  result = LevelMeta(name: name, path: path, contentHash: hash)

let officialLevels*:  OrderedTable[Path, level_data.LevelMeta] = @[
  newLevelMeta(name= "Tutorial: Accelerate", path="levels/dragster.wmj", hash="64b4ab49f49f96fc307dc4b0b55b32ab"),
  newLevelMeta(name= "Tutorial: Brake", path="levels/tutorial_brake.wmj", hash="6d2327b6bb9a7bbc95ee6db24f6c82c9"),
  newLevelMeta(name= "Tutorial: Balance", path="levels/tutorial_leaning.wmj", hash="71584fd5114a1ecafa63111a5a4f7354"),
  newLevelMeta(name= "Tutorial: Turn Around", path="levels/tutorial_turn_around.wmj", hash="8ae54214fef1696a6c3937a7effca5ec"),
  newLevelMeta(name= "Globe of Death", path="levels/globe_of_death.wmj", hash="20d68a3282a4098143271b72791c8db8"),
  newLevelMeta(name= "Looping", path="levels/looping.wmj", hash="eabf87e393d16a0ada15b1e65c13543c"),
  newLevelMeta(name= "Half Pipe", path="levels/halfpipe.wmj", hash="34bcc332e2046249dc08e84a7ad7edc6"),
  newLevelMeta(name= "Hills", path="levels/hills.wmj", hash="4475fd63968fa4afd7d814015fc91be6"),
  newLevelMeta(name= "Globe of Death 3", path="levels/globe_of_death_3.wmj", hash="96997bda344bcbdeedb8917b18df23ca"),
  newLevelMeta(name= "Tutorial: Gravity", path="levels/tutorial_gravity.wmj", hash="f365140dc92ec4a0cb9183a59f5e31c0"),
  newLevelMeta(name= "Wall Rider", path="levels/wall_rider.wmj", hash="d7fe74a6aac98d31c1d1e1491cb9465e"),
  newLevelMeta(name= "Gravity Vault", path="levels/gravity_vault.wmj", hash="15cba093ef71489540be367a67ca97b6"),
  newLevelMeta(name= "Marble Vault", path="levels/marble_vault.wmj", hash="665850195c64c027ffaf3f32062a5d89"),
  newLevelMeta(name= "Leg Up", path="levels/leg_up.wmj", hash="8451a6de4bdcd0dfd70bb4386c1c11c9"),
  newLevelMeta(name= "Backflip", path="levels/backflip.wmj", hash="1ef254c88f933e227f01333030ebb1f3"),
  newLevelMeta(name= "Killveyor", path="levels/killveyor.wmj", hash="474c7abbc411128e1d210705f32f3325"),
  newLevelMeta(name= "Hooked", path="levels/hooked.wmj", hash="ed66b93c85b997aaa67bd4541473fca1"),
  newLevelMeta(name= "Return to sender", path="levels/return_to_sender.wmj", hash="8076f8af661fa55073c2e10302aaafcb"),
  newLevelMeta(name= "Globe of Death 2", path="levels/globe_of_death_2.wmj", hash="722c2e6152072f982b81b61a9caa88f0"),
  newLevelMeta(name= "Level 1", path="levels/level1.wmj", hash="e952d400f5c49f35dd7a92af1d28244c"),
  newLevelMeta(name= "Level 2", path="levels/level2.wmj", hash="a5f8e1687cea5b902dcbbe43520ab531"),
  newLevelMeta(name= "Level 3", path="levels/level3.wmj", hash="38874823812ddaafe3623d32cc2a73ac"),
]
  .map(meta => (meta.path, meta)) # use path as key
  .toOrderedTable

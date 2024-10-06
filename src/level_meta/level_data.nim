import tables
import sugar
import sequtils
import common/shared_types

const 
  levelsBasePath* = "levels/"
  levelFileExtension* = ".wmj"

type
  LevelTheme*  {.pure.} = enum
    Bath, Bookshelf, Desk, Kitchen, Plants, Space
    
  LevelMeta* = ref object of RootObj
    name*: string
    path*: string
      ## path is used as id, must be unique (which it is, enforced by the file system)
    contentHash*: string
    theme*: LevelTheme

proc newLevelMeta*(name: string, path: Path, theme: LevelTheme, hash: string): LevelMeta =
  result = LevelMeta(name: name, path: path, theme: theme, contentHash: hash)

let officialLevels*: OrderedTable[Path, LevelMeta] = @[
  newLevelMeta(name= "Tutorial: Accelerate", path="levels/dragster.wmj", theme= Kitchen, hash="BE9DFBF65B3D445DE8D82B86EDC4E1A4"),
  newLevelMeta(name= "Tutorial: Brake", path="levels/tutorial_brake.wmj", theme= Kitchen, hash="7BC582C7E0CCB52271FC1C552C39B03C"),
  newLevelMeta(name= "Tutorial: Turn Around", path="levels/tutorial_turn_around.wmj", theme= Kitchen, hash="C7AC5FA16E536FD7B5877E2933C48F77"),
  
  newLevelMeta(name= "Tutorial: Balance", path="levels/tutorial_leaning.wmj", theme= Bath, hash="01F0CF4002245355B69E15DFEEF89129"),
  newLevelMeta(name= "King of the Hill", path="levels/king_of_the_hill.wmj", theme= Bath, hash="530C15AECF7BD96722F0AE63EB4CF889"),
  newLevelMeta(name= "Hills", path="levels/hills.wmj", theme= Bath, hash="F2B95FD95A573064029F3867780CC049"),
  newLevelMeta(name= "Globe of Death", path="levels/globe_of_death.wmj", theme= Bath, hash="7DADFE4906AEA50DCE99C8EF8856A155"),
  
  newLevelMeta(name= "Treasure Tunnel", path="levels/treasure_tunnel.wmj", theme= Plants, hash="43236BC73E486BEAB232047C5325F81F"),
  newLevelMeta(name= "Globe of Death 2", path="levels/globe_of_death_2.wmj", theme= Plants, hash="B77D48CABAFAAA0B0D15C24BB71E8F20"),

  newLevelMeta(name= "Looping", path="levels/looping.wmj", theme= Bookshelf, hash="09E1D670FB15EEBDD43B9553A13B7C44"),
  newLevelMeta(name= "Hooked", path="levels/hooked.wmj", theme= Bookshelf, hash="032338DBDFE3050DC49D1ADD8399C08B"),
  newLevelMeta(name= "Upside Down Hook", path="levels/upside_down_hook.wmj", theme= Bookshelf, hash="F45AC5C12A56A8DB8B3FED7B876D58CE"),
  newLevelMeta(name= "Backflip", path="levels/backflip.wmj", theme= Bookshelf, hash="94BED03D22F37143B309642C470BD13A"),
  newLevelMeta(name= "Dominoes", path="levels/dominoes.wmj", theme= Bookshelf, hash="086BF75F2F450A12FF09C8F091551AAE"),

  newLevelMeta(name= "Tutorial: Gravity", path="levels/tutorial_gravity.wmj", theme= Space, hash="EFC2DC6190DC8B4A7EF66717ED670F41"),
  newLevelMeta(name= "Wall Rider", path="levels/wall_rider.wmj", theme= Space, hash="2DCF04460B8B4CC1C98FB1AB8A723BC8"),
  newLevelMeta(name= "Gravity Vault", path="levels/gravity_vault.wmj", theme= Space, hash="89DAA07AD9C1D233AAC1452B7B97CAF9"),
  newLevelMeta(name= "Marble Vault", path="levels/marble_vault.wmj", theme= Space, hash="72EBC04A2B2FEB6F25F0F0DB257A5B4B"),
  newLevelMeta(name= "Killveyor", path="levels/killveyor.wmj", theme= Space, hash="B2D46C9F2EE4A7C1CF52782699FA2C25"),
  newLevelMeta(name= "Return to sender", path="levels/return_to_sender.wmj", theme= Space, hash="979F6AE3DE110379B4A8339836EC6447"),

  newLevelMeta(name= "Globe of Death 3", path="levels/globe_of_death_3.wmj", theme= Plants, hash="A2808675431EB16A330D0FBB80ED308C"),
  newLevelMeta(name= "Half Pipe", path="levels/halfpipe.wmj", theme= Plants, hash="E94DA2D6BF77DACCDCB44A9CF9726D81"),
  newLevelMeta(name= "Rickety Bridge", path="levels/rickety_bridge.wmj", theme= Plants, hash="5FAF9FBA2F251B2D5FE031F2BEB2DB05"),

  newLevelMeta(name= "Zig Zag Down", path="levels/zig_zag_down.wmj", theme= Desk, hash="BF0CB5582123B414261B2D3F89CDE21C"),
  newLevelMeta(name= "Leg Up", path="levels/leg_up.wmj", theme= Desk, hash="7F6453E5EFA13901F608BBED31464EE0"),
  newLevelMeta(name= "Ballancing Act", path="levels/ballancing_act.wmj", theme= Desk, hash="B60DEEC52E7B66F85267C785D96184AE"),
  newLevelMeta(name= "Leap of Faith", path="levels/leap_of_faith.wmj", theme= Desk, hash="D4144D0F72A80AA712F236A616AF3D97")
]
  .map(meta => (meta.path, meta)) # use path as key
  .toOrderedTable

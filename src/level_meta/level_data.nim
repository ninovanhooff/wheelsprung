{.push raises: [].}

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
  newLevelMeta(name= "Tutorial: Accelerate", path="levels/dragster.wmj", theme= Kitchen, hash="4BCC8CCB3F019586DBD3FC749D76DC50"),
  newLevelMeta(name= "Tutorial: Brake", path="levels/tutorial_brake.wmj", theme= Kitchen, hash="3747BDEF40C513843AEB76CF36FFE750"),
  newLevelMeta(name= "Tutorial: Turn Around", path="levels/tutorial_turn_around.wmj", theme= Kitchen, hash="E751FAC8747A40C9B7B81E108B71A73A"),
  
  newLevelMeta(name= "Tutorial: Balance", path="levels/tutorial_leaning.wmj", theme= Bath, hash="FAF07A1B8B14F20E349AAD05F0FC7A8D"),
  newLevelMeta(name= "Towel Trial", path="levels/towel_trial.wmj", theme= Bath, hash="647A30204555BF33C7CD9BEFE17002E1"),
  newLevelMeta(name= "Ripple Ride", path="levels/hills.wmj", theme= Bath, hash="EE9CE18CF99447145C813C6F52417B9A"),
  newLevelMeta(name= "Laundry Loop", path="levels/globe_of_death.wmj", theme= Bath, hash="56FC52E55FAFF1A1D762B9B529ABC0AB"),
  newLevelMeta(name= "Ripcurl Rush", path="levels/looping.wmj", theme= Bath, hash="4EAA4829FCD2AB20D79455849BC69C65"),


  newLevelMeta(name= "Hooked", path="levels/hooked.wmj", theme= Bookshelf, hash="A19C795ACD4E767DB78059B362FAE50C"),
  newLevelMeta(name= "Upside Down Hook", path="levels/upside_down_hook.wmj", theme= Bookshelf, hash="07E579B5F483454DA8317F2F1277E9F0"),
  newLevelMeta(name= "Backflip", path="levels/backflip.wmj", theme= Bookshelf, hash="BEFEAFDE2090C77399C2115F8BACA82C"),
  newLevelMeta(name= "Dominoes", path="levels/dominoes.wmj", theme= Bookshelf, hash="19FF82C50A0ED49B64617535113EF0C3"),


  newLevelMeta(name= "Tutorial: Gravity", path="levels/tutorial_gravity.wmj", theme= Space, hash="D515B80D7961D381F24784F95FE566D9"),
  newLevelMeta(name= "Wall Rider", path="levels/wall_rider.wmj", theme= Space, hash="289CE0F59B13B17C6C24E11366ED99C0"),
  newLevelMeta(name= "Gravity Vault", path="levels/gravity_vault.wmj", theme= Space, hash="B2F2A60C18E62BB71440DE4A52D19D9C"),
  newLevelMeta(name= "Marble Vault", path="levels/marble_vault.wmj", theme= Space, hash="EDE635525EE24A08A56B6597FB394903"),
  newLevelMeta(name= "Killveyor", path="levels/killveyor.wmj", theme= Space, hash="01F13539BF2C80BA51C6493C8EBE7D3E"),
  newLevelMeta(name= "Return to sender", path="levels/return_to_sender.wmj", theme= Space, hash="38786445A7556330267493A3984ED90E"),

  newLevelMeta(name= "Treasure Tunnel", path="levels/treasure_tunnel.wmj", theme= Plants, hash="8794DC01BABFDA156334585A86EF000B"),
  newLevelMeta(name= "Globe of Death 3", path="levels/globe_of_death_3.wmj", theme= Plants, hash="6C2F198E9F13954B832ECC78D605BCBC"),
  newLevelMeta(name= "Half Pipe", path="levels/halfpipe.wmj", theme= Plants, hash="052A6854A05D68DC806296A6E5C64F70"),
  newLevelMeta(name= "Rickety Bridge", path="levels/rickety_bridge.wmj", theme= Plants, hash="DC16167AB074178813D718F340A11E53"),

  newLevelMeta(name= "Zig Zag Down", path="levels/zig_zag_down.wmj", theme= Desk, hash="65492135DDF3E619FF3790D8B09727D8"),
  newLevelMeta(name= "Leg Up", path="levels/leg_up.wmj", theme= Desk, hash="0B16E215044C42D19BDFC8F3CEA158F1"),
  newLevelMeta(name= "Ballancing Act", path="levels/ballancing_act.wmj", theme= Desk, hash="49CC4A72B29B501B2B3ACCB68E678248"),
  newLevelMeta(name= "Leap of Faith", path="levels/leap_of_faith.wmj", theme= Desk, hash="8FFCAD8B3D12CA55EEE0A99F1FFCBE37")
]
  .map(meta => (meta.path, meta)) # use path as key
  .toOrderedTable

proc createUserLevelMeta(levelPath: Path): LevelMeta =
  # for unknown levels, add them to the list using path as name
  return newLevelMeta(
    name = levelPath[levelsBasePath.len .. ^1],
    path = levelPath,
    hash = "no hash: user level",
    theme = LevelTheme.Space
  )

proc getLevelMeta*(path: Path): LevelMeta =
  try:
    return officialLevels[path]
  except KeyError:
    return createUserLevelMeta(path)
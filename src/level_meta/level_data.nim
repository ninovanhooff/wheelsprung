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
  newLevelMeta(name= "Tutorial: Accelerate", path="levels/dragster.wmj", theme= Kitchen, hash="B9FDE9584DCE48CA66AC6EB840FDB013"),
  newLevelMeta(name= "Tutorial: Brake", path="levels/tutorial_brake.wmj", theme= Kitchen, hash="3747BDEF40C513843AEB76CF36FFE750"),
  newLevelMeta(name= "Tutorial: Turn Around", path="levels/tutorial_turn_around.wmj", theme= Kitchen, hash="27BE36E566DD5B3E08C4BD2DCD459E70"),
  
  newLevelMeta(name= "Tutorial: Balance", path="levels/tutorial_leaning.wmj", theme= Bath, hash="FAF07A1B8B14F20E349AAD05F0FC7A8D"),
  newLevelMeta(name= "King of the Hill", path="levels/king_of_the_hill.wmj", theme= Bath, hash="4F3971882971A1296E8B85BFA3C6EC61"),
  newLevelMeta(name= "Hills", path="levels/hills.wmj", theme= Bath, hash="EE9CE18CF99447145C813C6F52417B9A"),
  newLevelMeta(name= "Globe of Death", path="levels/globe_of_death.wmj", theme= Bath, hash="D52B0303CF760CEF45C307B055780AB3"),
  
  newLevelMeta(name= "Treasure Tunnel", path="levels/treasure_tunnel.wmj", theme= Plants, hash="8794DC01BABFDA156334585A86EF000B"),
  newLevelMeta(name= "Globe of Death 2", path="levels/globe_of_death_2.wmj", theme= Plants, hash="FB0A20BF3B27A8E41F154773C5323EF4"),

  newLevelMeta(name= "Looping", path="levels/looping.wmj", theme= Bookshelf, hash="4D1C4F8808A02E810D4409A8E6B045E8"),
  newLevelMeta(name= "Hooked", path="levels/hooked.wmj", theme= Bookshelf, hash="A19C795ACD4E767DB78059B362FAE50C"),
  newLevelMeta(name= "Upside Down Hook", path="levels/upside_down_hook.wmj", theme= Bookshelf, hash="07E579B5F483454DA8317F2F1277E9F0"),
  newLevelMeta(name= "Backflip", path="levels/backflip.wmj", theme= Bookshelf, hash="BEFEAFDE2090C77399C2115F8BACA82C"),
  newLevelMeta(name= "Dominoes", path="levels/dominoes.wmj", theme= Bookshelf, hash="5674D2D09D852EB0720DC9DE6EA070CE"),

  newLevelMeta(name= "Tutorial: Gravity", path="levels/tutorial_gravity.wmj", theme= Space, hash="D515B80D7961D381F24784F95FE566D9"),
  newLevelMeta(name= "Wall Rider", path="levels/wall_rider.wmj", theme= Space, hash="289CE0F59B13B17C6C24E11366ED99C0"),
  newLevelMeta(name= "Gravity Vault", path="levels/gravity_vault.wmj", theme= Space, hash="B94D1B805D492033CD17456BC2DE11CA"),
  newLevelMeta(name= "Marble Vault", path="levels/marble_vault.wmj", theme= Space, hash="AC05F0577E2ADC7A22DB3DD0EBBC71DA"),
  newLevelMeta(name= "Killveyor", path="levels/killveyor.wmj", theme= Space, hash="01F13539BF2C80BA51C6493C8EBE7D3E"),
  newLevelMeta(name= "Return to sender", path="levels/return_to_sender.wmj", theme= Space, hash="38786445A7556330267493A3984ED90E"),

  newLevelMeta(name= "Globe of Death 3", path="levels/globe_of_death_3.wmj", theme= Plants, hash="6C2F198E9F13954B832ECC78D605BCBC"),
  newLevelMeta(name= "Half Pipe", path="levels/halfpipe.wmj", theme= Plants, hash="052A6854A05D68DC806296A6E5C64F70"),
  newLevelMeta(name= "Rickety Bridge", path="levels/rickety_bridge.wmj", theme= Plants, hash="DC16167AB074178813D718F340A11E53"),

  newLevelMeta(name= "Zig Zag Down", path="levels/zig_zag_down.wmj", theme= Desk, hash="65492135DDF3E619FF3790D8B09727D8"),
  newLevelMeta(name= "Leg Up", path="levels/leg_up.wmj", theme= Desk, hash="A7C98CE33E9EBE2DF950AE4672CC1D56"),
  newLevelMeta(name= "Ballancing Act", path="levels/ballancing_act.wmj", theme= Desk, hash="49CC4A72B29B501B2B3ACCB68E678248"),
  newLevelMeta(name= "Leap of Faith", path="levels/leap_of_faith.wmj", theme= Desk, hash="8FFCAD8B3D12CA55EEE0A99F1FFCBE37")
]
  .map(meta => (meta.path, meta)) # use path as key
  .toOrderedTable

{.push raises: [].}

import std/strutils
import std/tables
import std/sugar
import std/sequtils
import std/options
import common/shared_types
import common/utils

const 
  levelsBasePath* = "levels/"
  jsonLevelFileExtension* = "wmj"
  jsonLevelFileExtensionWithDot* = "." & jsonLevelFileExtension
  flattyLevelFileExtension* = "flatty"
  flattyLevelFileExtensionWithDot* = "." & flattyLevelFileExtension

type
  LevelTheme*  {.pure.} = enum
    Bath, Bookshelf, Desk, Kitchen, Plants, Space
    
  LevelMeta* = ref object of RootObj
    name*: string
    scoreboardId*: string
    path*: string
      ## path is used as id, must be unique (which it is, enforced by the file system)
    contentHash*: string
    theme*: LevelTheme

proc isLevelFile*(path: string): bool =
  return path.endsWith(jsonLevelFileExtensionWithDot) or path.endsWith(flattyLevelFileExtensionWithDot)

proc newLevelMeta*(name: string, path: Path, theme: LevelTheme, hash: string, boardId: string = ""): LevelMeta =
  result = LevelMeta(name: name, scoreboardId: boardId, path: path, theme: theme, contentHash: hash)

let officialLevels*: OrderedTable[Path, LevelMeta] = @[
  newLevelMeta(name= "Tutorial: Throttle", path="levels/dragster.flatty", theme= Kitchen, hash="87EF3CC160DE2D1C0804CF36ABA223B4", boardId = "tutorialaccelerate"),
  newLevelMeta(name= "Tutorial: Brake", path="levels/tutorial_brake.flatty", theme= Kitchen, hash="9D47D61C3598C885BAA933B4A80AE172", boardId = "tutorialbrake"),
  newLevelMeta(name= "Tutorial: Turning", path="levels/tutorial_turn_around.flatty", theme= Kitchen, hash="9089CE2DEDB0D7F36AD724CDAA90AA89", boardId = "tutorialturnaround"),
  
  newLevelMeta(name= "Tutorial: Balance", path="levels/tutorial_leaning.flatty", theme= Bath, hash="F56F62ED85D51DA493C590FEF71A3F0B"),
  newLevelMeta(name= "Leap of Faith", path="levels/leap_of_faith.flatty", theme= Desk, hash="6A7FBB2524358A86BF4A1F96FDE24CD1"),
  newLevelMeta(name= "Towel Trial", path="levels/towel_trial.flatty", theme= Bath, hash="FA763F59170C357953CE30B29FBC5667"),
  newLevelMeta(name= "Ripple Ride", path="levels/hills.flatty", theme= Bath, hash="5E6783CF62C2C15ED73282CCE633D66B"),
  newLevelMeta(name= "Laundry Loop", path="levels/globe_of_death.flatty", theme= Bath, hash="297651CFFAA6E83E1703E465A158E6B1"),
  newLevelMeta(name= "Ripcurl Rush", path="levels/looping.flatty", theme= Bath, hash="3B6D26825A9D30FEAA364F13B03953F5", boardId = "hills"),

  newLevelMeta(name= "Novel Navigations", path="levels/novel_navigations.flatty", theme= Bookshelf, hash="83D025E12A1140BC3B86831F20FF4622"),
  newLevelMeta(name= "Under Covers", path="levels/under_covers.flatty", theme= Bookshelf, hash="07C4F9B28FA27A1EDB706A9432544979"),
  newLevelMeta(name= "Hooked", path="levels/hooked.flatty", theme= Bookshelf, hash="C83A58916A6F97F1AA0A2952E12BFABA"),
  newLevelMeta(name= "Backflip", path="levels/backflip.flatty", theme= Bookshelf, hash="513A5202C29C322690EE9B33068D6789"),
  newLevelMeta(name= "Dominoes", path="levels/dominoes.flatty", theme= Bookshelf, hash="19A67112C03DA92C9D51FB268956F93C"),

  newLevelMeta(name= "Tutorial: Gravity", path="levels/tutorial_gravity.flatty", theme= Space, hash="E1C388DD1554CA7B27FB5753C07B434B"),
  newLevelMeta(name= "Wall Rider", path="levels/wall_rider.flatty", theme= Space, hash="90DDCFE21872F9CBF4AB9693F4C36784"),
  newLevelMeta(name= "Gravity Vault", path="levels/gravity_vault.flatty", theme= Space, hash="99865E7F90943DB1DC7EBC793DD4FC41"),
  newLevelMeta(name= "Marble Vault", path="levels/marble_vault.flatty", theme= Space, hash="E86B172095D41D35AC16C57AC918AFA8"),
  newLevelMeta(name= "Killveyor", path="levels/killveyor.flatty", theme= Space, hash="62CD10EDDA94748B614B9A8E07E5E6A8"),
  newLevelMeta(name= "Ludicrous Launch", path="levels/ludicrous_launch.flatty", theme= Space, hash="5CC9E809001ED5E0C07144F2CE92F478"),

  newLevelMeta(name= "Globe of Death 3", path="levels/globe_of_death_3.flatty", theme= Plants, hash="6C2AFA63DB64AD88EB324918BEA8B557"),
  newLevelMeta(name= "Treasure Tunnel", path="levels/treasure_tunnel.flatty", theme= Plants, hash="6E5F2C44C7ED48F25ED86E834C68149B"),
  newLevelMeta(name= "Half Pipe", path="levels/halfpipe.flatty", theme= Plants, hash="AD044D60F6F6C95534182E7C7C105AE6"),
  newLevelMeta(name= "Rickety Bridge", path="levels/rickety_bridge.flatty", theme= Plants, hash="0CF980DB09C2EE873C16836319B51CBD"),

  newLevelMeta(name= "Zig Zag Down", path="levels/zig_zag_down.flatty", theme= Desk, hash="633154C6A64C4C0EB4FCC1FE1F0490B0"),
  newLevelMeta(name= "Leg Up", path="levels/leg_up.flatty", theme= Desk, hash="6F48907EB90D6985CB66486C4A11FFEC"),
  newLevelMeta(name = "Tight Squeeze", path="levels/tight_squeeze.flatty", theme= Desk, hash="0541EF41C104AE11FFCE43B3B3077A85"),
  newLevelMeta(name = "Time Traveler", path="levels/time_traveler.flatty", theme= Desk, hash="5FC184DB975025507BBAD29BE27E9322"),
  newLevelMeta(name= "Ballancing Act", path="levels/ballancing_act.flatty", theme= Desk, hash="15B0EC58F7BB8A9912DB470DE0CCA81F"),
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

proc getMetaByBoardId*(boardId: string): Option[LevelMeta] =
  return officialLevels.values.toSeq.findFirst(it => it.scoreboardId == boardId)

proc getFirstOfficialLevelMeta*(): LevelMeta =
  return officialLevels.values.toSeq[0]
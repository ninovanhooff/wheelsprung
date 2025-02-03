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
  newLevelMeta(name= "Tutorial: Throttle", path="levels/dragster.flatty", theme= Kitchen, hash="5E34766E91D5B237530B5B0B9810053A", boardId = "tutorialaccelerate"),
  newLevelMeta(name= "Tutorial: Brake", path="levels/tutorial_brake.flatty", theme= Kitchen, hash="B77D84130D44E29A58D5C6851F9335C9", boardId = "tutorialbrake"),
  newLevelMeta(name= "Tutorial: Turning", path="levels/tutorial_turn_around.flatty", theme= Kitchen, hash="624B6D19EA019A83718A3B3D60BCF784", boardId = "tutorialturnaround"),
  
  newLevelMeta(name= "Tutorial: Balance", path="levels/tutorial_leaning.flatty", theme= Bath, hash="14AB64B792F3289B4543D35043DA2006" , boardId = "tutorialbalance"),
  newLevelMeta(name= "Leap of Faith", path="levels/leap_of_faith.flatty", theme= Desk, hash="EEC78847587BE6ACC3AB2E148A378E16", boardId = "leapoffaith"),
  newLevelMeta(name= "Towel Trial", path="levels/towel_trial.flatty", theme= Bath, hash="DA0A2C427905CE6AFE0C517267CD1BDE", boardId = "toweltrial"),
  newLevelMeta(name= "Ripple Ride", path="levels/hills.flatty", theme= Bath, hash="B761D4E4CE698D1098E38C18745B900B", boardId = "hills"),
  newLevelMeta(name= "Laundry Loop", path="levels/globe_of_death.flatty", theme= Bath, hash="496977DBF544B5430FFCC5F8F6550547", boardId = "laundryloop"),
  newLevelMeta(name= "Ripcurl Rush", path="levels/looping.flatty", theme= Bath, hash="ED9C09C0A119D9CE9FDC923B2235512D", boardId = "ripcurlrush"),

  newLevelMeta(name= "Novel Navigations", path="levels/novel_navigations.flatty", theme= Bookshelf, hash="35D56F2B63EF2C082EBB892D45730FCF", boardId = "novelnavigations"),
  newLevelMeta(name= "Shelf Swinger", path="levels/shelf_swinger.flatty", theme= Bookshelf, hash="F982995B1460C9B2AA0BF991A8947D40", boardId = "shelfswinger"),
  newLevelMeta(name= "Hooked", path="levels/hooked.flatty", theme= Bookshelf, hash="DE060B014C4EECFD4AEF7E0F618556B3", boardId = "hooked"),
  newLevelMeta(name= "Dominoes", path="levels/dominoes.flatty", theme= Bookshelf, hash="3916A43742286FCFDE36BB5F2B89B513", boardId = "dominoes"),
  newLevelMeta(name= "Rollercoaster", path="levels/rollercoaster.flatty", theme= Bookshelf, hash="51332761CC207FFB4D6A64204B23EE58", boardId = "rollercoaster"),
  newLevelMeta(name= "Under Covers", path="levels/under_covers.flatty", theme= Bookshelf, hash="60EF5797CE21F71F0490BBE076978AAE", boardId = "undercovers"),
  newLevelMeta(name= "Backflip", path="levels/backflip.flatty", theme= Bookshelf, hash="08DEC7512B3E7D0DD439A645714477CC", boardId = "backflip"),

  newLevelMeta(name= "Tutorial: Gravity", path="levels/tutorial_gravity.flatty", theme= Space, hash="8A65ADE8AD9AACDDC2CFE966E20AE26A", boardId = "tutorialgravity"),
  newLevelMeta(name= "Wall Rider", path="levels/wall_rider.flatty", theme= Space, hash="A8B2F9019019ADB3B92FB8B3D35CEA18", boardId = "wallrider"),
  newLevelMeta(name= "Gravity Vault", path="levels/gravity_vault.flatty", theme= Space, hash="A0D8F6E03D82F25A00E0007B4034EBC5", boardId = "gravityvault"),
  newLevelMeta(name= "Marble Vault", path="levels/marble_vault.flatty", theme= Space, hash="8A8D6A588175E84D38F559440C16F856", boardId = "marblevault"),
  newLevelMeta(name= "Killveyor", path="levels/killveyor.flatty", theme= Space, hash="7D1F01333033DD886DFEFBF892E846F4", boardId = "killveyor"),
  newLevelMeta(name= "Ludicrous Launch", path="levels/ludicrous_launch.flatty", theme= Space, hash="888FCC60ADC85E08E190DAB7BA5C031C", boardId = "ludicrouslaunch"),

  newLevelMeta(name= "Circle of Life", path="levels/globe_of_death_3.flatty", theme= Plants, hash="4F3A5C6B6405D82F2E921D9D75B86775", boardId = "circleoflife"),
  newLevelMeta(name= "Treasure Tunnel", path="levels/treasure_tunnel.flatty", theme= Plants, hash="4E719F250D53A334A369D281F15437E9", boardId = "treasuretunnel"),
  newLevelMeta(name= "Half-Pipe Jungle", path="levels/halfpipe.flatty", theme= Plants, hash="31CAC03643E131EEFBD3050D4F89E290", boardId = "halfpipejungle"),
  newLevelMeta(name= "Rickety Bridge", path="levels/rickety_bridge.flatty", theme= Plants, hash="9334B9D0948020ABFA16912C36E273E1", boardId = "ricketybridge"),
  newLevelMeta(name = "Rolling Raiders", path="levels/boulder.flatty", theme= Plants, hash="9876055452FCFB8D5727B5C9FE455C51", boardId = "rollingraiders"),

  newLevelMeta(name= "Zig Zag Down", path="levels/zig_zag_down.flatty", theme= Desk, hash="775D968527AB35C7E25BAAD512EB3878", boardId = "zigzagdown"),
  newLevelMeta(name = "Time Traveler", path="levels/time_traveler.flatty", theme= Desk, hash="FAF8E4D22D57ACD6899241B6BA547188", boardId = "timetraveler"),
  newLevelMeta(name = "Tight Squeeze", path="levels/tight_squeeze.flatty", theme= Desk, hash="E918A9D751CF34C351B10E3EDE3462B4", boardId = "tightsqueeze"),
  newLevelMeta(name= "Ballistic Bowler", path="levels/ballistic_bowler.flatty", theme= Desk, hash="E64D63A878E1B5F6D70F6AB9BDFA539D", boardId = "ballisticbowler"),
  newLevelMeta(name= "Ramp of Pages", path="levels/ramp_of_pages.flatty", theme= Desk, hash="FFE4140194259B6B4BD194C078FCA558", boardId = "rampofpages"),
  newLevelMeta(name= "Ballancing Act", path="levels/ballancing_act.flatty", theme= Desk, hash="AEA07FDE8004427F8959C741F2F5CB31", boardId = "ballancingact"),

  newLevelMeta(name= "Go Nuts!", path="levels/paradise.flatty", theme= Space, hash="90C6984E1062ACF94E825CF96EB915B7", boardId = "paradise"),
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
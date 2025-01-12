{.push raises: [].}

import std/tables
import std/options
import std/strutils
import common/shared_types
import common/data_utils
import common/utils
import common/integrity
import common/save_slot_types

const 
  saveSlotVersion = 1
  filePath = "saveslot1.json"

var saveSlot: SaveSlot
  ## Global singleton

proc getLevelProgress*(id: Path): LevelProgress =
  try:
    result = saveSlot.progress[id]
    if result.verify(id) == false:
      raise newException(CatchableError, "Integrity check failed for level progress")
  except CatchableError:
    # print (getCurrentExceptionMsg(), id)
    result = newLevelProgress(levelId = id, bestTime = none(Milliseconds), hasCollectedStar = false, signature = none(string))
    saveSlot.progress[id] = result

proc setLevelProgress*(id: Path, progress: LevelProgress) =
  print ("Setting progress for level", id, repr(progress))
  saveSlot.progress[id] = progress

proc isStarEnabled*(id: Path): bool =
  let progress = getLevelProgress(id)
  result = progress.bestTime.isSome

proc getPlayerName*(): Option[string] =
  return saveSlot.playerName

proc setPlayerName*(name: string) =
  print "Setting player name to:", name
  saveSlot.playerName = some(name)

proc getRestoreState*(): Option[RestoreState] =
  return saveSlot.restoreState

proc setRestoreState*(restoreState: RestoreState) =
  saveSlot.restoreState = some(restoreState)

proc loadSaveSlot(): SaveSlot =
  print "loadSaveSlot"
  let optSaveSlotEntity = loadJson[SaveSlotEntity](filePath)
  let optSaveSlot = optSaveSlotEntity.map(saveSlotFromEntity)
  if optSaveSlot.isSome:
    saveSlot = optSaveSlot.get
    print("Loaded save slot")
  else:
    print("Creating new save slot")
    saveSlot = SaveSlot(
      progress: initTable[Path, LevelProgress](), 
      modelVersion: saveSlotVersion
    )
    # we usually end up here when the data folder doesn't exist yet.
    # this is a good time to create the levels folder too.
    makeDir("levels")
    print("Created new save slot and ensured levels folder exists")
  result = saveSlot

proc getSaveSlot*(): SaveSlot =
  if saveSlot == nil:
    result = loadSaveSlot()
  else:
    result = saveSlot

proc saveSaveSlot*() =
  print ("Saving save slot")
  saveSlotToEntity(saveSlot).saveJson(filePath)

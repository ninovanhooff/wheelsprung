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

type NoSignatureError = object of ValueError

proc setEmptyLevelProgress(levelId: Path): LevelProgress =
  let progress = newLevelProgress(levelId = levelId, bestTime = none(Milliseconds), hasCollectedStar = false, signature = none(string))
  saveSlot.progress[levelId] = progress
  return progress

proc getLevelProgress*(id: Path): LevelProgress =
  if saveSlot.isNil:
    print "ERROR: saveSlot is nil. CREATING EMPTY saveslot"
    saveSlot = SaveSlot()
  try:
    let progress = saveSlot.progress[id]
    if progress.signature.isNone:
      raise newException(NoSignatureError, "No signature found for level progress")
    if progress.verify(id) == false:
      raise newException(CatchableError, "Integrity check failed for level progress")
    return progress
  except NoSignatureError:
    return setEmptyLevelProgress(id)
  except CatchableError:
    print getCurrentExceptionMsg(), id
    return setEmptyLevelProgress(id)

proc setLevelProgress*(id: Path, progress: LevelProgress) =
  print "Setting progress for level", id
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

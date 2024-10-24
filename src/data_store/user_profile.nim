{.push raises: [].}

import std/tables
import std/options
import std/strutils
import common/shared_types
import common/data_utils
import common/utils
import common/integrity
import common/save_slot_types
import level_meta/level_data

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

proc isStarEnabled*(id: Path): bool =
  let progress = getLevelProgress(id)
  result = progress.bestTime.isSome

proc updateLevelProgress*(gameResult: GameResult) =
  let id = gameResult.levelId

  case gameResult.resultType
    of GameResultType.GameOver:
      return
    of GameResultType.LevelComplete:
      discard # Continue to update progress
  
  var progress: LevelProgress = getLevelProgress(id)
  let bestTime = progress.bestTime.get(Milliseconds.high)
  if gameResult.time < bestTime :
    print ("New best time", gameResult.time, "for level", id)
    progress.bestTime = some(gameResult.time)

  if gameResult.starCollected:
    print ("Collected star for level", id)
    progress.hasCollectedStar = true

  let levelMeta = officialLevels.getOrDefault(id, nil)
  # only official levels need a content hash
  if levelMeta == nil or levelMeta.contentHash == gameResult.levelHash:
    progress.sign()
  else:
    print "WARN Level content hash mismatch for level", id
    progress.signature = none(string)
  print ("Saving progress for level", id, repr(progress))
  saveSlot.progress[id] = progress

proc setLastOpenedLevel*(levelPath: string) =
  saveSlot.lastOpenedLevel = some(levelPath)

proc getRestoreState*(): Option[RestoreState] =
  return saveSlot.restoreState

proc setRestoreState*(restoreState: RestoreState) =
  saveSlot.restoreState = some(restoreState)

proc loadSaveSlot*(): SaveSlot =
  let optSaveSlotEntity = loadJson[SaveSlotEntity](filePath)
  let optSaveSlot = optSaveSlotEntity.map(saveSlotFromEntity)
  if optSaveSlot.isSome:
    saveSlot = optSaveSlot.get
    print("Loaded save slot")
  else:
    saveSlot = SaveSlot(
      progress: initTable[Path, LevelProgress](), 
      modelVersion: saveSlotVersion
    )
    print("Created new save slot")
  result = saveSlot

proc getSaveSlot*(): SaveSlot =
  if saveSlot == nil:
    result = loadSaveSlot()
  else:
    result = saveSlot

proc saveSaveSlot*() =
  print ("Saving save slot")
  saveSlotToEntity(saveSlot).saveJson(filePath)

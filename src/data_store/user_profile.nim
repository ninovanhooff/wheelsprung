{.push raises: [].}

import std/tables
import std/options
import std/strutils
import common/shared_types
import common/data_utils
import common/utils
import common/save_slot_types

const 
  saveSlotVersion = 1
  filePath = "saveslot1.json"

var saveSlot: SaveSlot
  ## Global singleton

proc getLevelProgress*(id: Path): LevelProgress =
  try:
    result = saveSlot.progress[id]
  except KeyError:
    print ("Creating new progress for level", id)
    result = LevelProgress(levelId: id)
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

  print ("Saving progress for level", id, repr(progress))
  saveSlot.progress[id] = progress

proc setLastOpenedLevel*(levelPath: string) =
  saveSlot.lastOpenedLevel = some(levelPath)

proc loadSaveSlot*(): SaveSlot =
  let optSaveSlotEntity = loadJson[SaveSlotEntity](filePath)
  let optSaveSlot = optSaveSlotEntity.map(saveSlotFromEntity)
  if optSaveSlot.isSome:
    saveSlot = optSaveSlot.get
    print("Loaded save slot", saveSlot.repr)
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
  saveSlotToEntity(saveSlot).saveJson(filePath)

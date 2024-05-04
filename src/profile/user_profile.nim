import tables
import options
import common/shared_types
import level_meta/level_data
import common/json_utils

const 
  saveSlotVersion = 1
  filePath = "user_profile.json"


type 
  LevelProgress* = ref object of RootObj
    levelId: LevelId
    bestTime: Option[Seconds]
    hasCollectedStar: bool
  
  SaveSlot* {.requiresInit.} = ref object of RootObj
    progress: Table[LevelId, LevelProgress]
    modelVersion: int

var saveSlot: SaveSlot
  ## Global singleton

proc getOrInsertProgress(id: LevelId): LevelProgress =
  if saveSlot.progress.hasKey(id):
    result = saveSlot.progress[id]
  else:
    result = LevelProgress(levelId: id)
    saveSlot.progress[id] = result

proc setBestTime*(id: LevelId, time: Seconds) =
  let progress: LevelProgress = getOrInsertProgress(id)
  progress.bestTime = some(time)

proc getBestTime*(id: LevelId): Option[Seconds] =
  if saveSlot.progress.hasKey(id):
    result = saveSlot.progress[id].bestTime
  else:
    result = none(Seconds)

proc setHasCollectedStar*(id: LevelId) =
  let progress: LevelProgress = getOrInsertProgress(id)
  progress.hasCollectedStar = true

proc getHasCollectedStar*(id: LevelId): bool =
  if saveSlot.progress.hasKey(id):
    result = saveSlot.progress[id].hasCollectedStar
  else:
    result = false

proc loadSaveSlot*(): SaveSlot =
  let optSaveSlot = loadJson[SaveSlot](filePath)
  if optSaveSlot.isSome:
    saveSlot = optSaveSlot.get
  else:
    saveSlot = SaveSlot(
      progress: initTable[LevelId, LevelProgress](), 
      modelVersion: saveSlotVersion
    )
  result = saveSlot

proc getSaveSlot*(): SaveSlot =
  if saveSlot == nil:
    result = loadSaveSlot()
  else:
    result = saveSlot

proc save*() =
  saveSlot.saveJson(filePath)
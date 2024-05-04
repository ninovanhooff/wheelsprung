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
    levelId: Path
    bestTime: Option[Seconds]
    hasCollectedStar: bool
  
  SaveSlot* {.requiresInit.} = ref object of RootObj
    progress: Table[Path, LevelProgress]
    modelVersion: int

var saveSlot: SaveSlot
  ## Global singleton

proc getOrInsertProgress(id: Path): LevelProgress =
  if saveSlot.progress.hasKey(id):
    result = saveSlot.progress[id]
  else:
    result = LevelProgress(levelId: id)
    saveSlot.progress[id] = result

proc setBestTime*(id: Path, time: Seconds) =
  let progress: LevelProgress = getOrInsertProgress(id)
  progress.bestTime = some(time)

proc getBestTime*(id: Path): Option[Seconds] =
  if saveSlot.progress.hasKey(id):
    result = saveSlot.progress[id].bestTime
  else:
    result = none(Seconds)

proc setHasCollectedStar*(id: Path) =
  let progress: LevelProgress = getOrInsertProgress(id)
  progress.hasCollectedStar = true

proc getHasCollectedStar*(id: Path): bool =
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
      progress: initTable[Path, LevelProgress](), 
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

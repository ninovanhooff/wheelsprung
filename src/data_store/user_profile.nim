import tables
import options
import common/shared_types
import common/json_utils
import common/utils

const 
  saveSlotVersion = 1
  filePath = "saveslot1.json"


type 
  LevelProgress* = ref object of RootObj
    levelId: Path
    bestTime: Option[Seconds]
    hasCollectedStar: bool
  
  SaveSlot* = ref object of RootObj
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
  var progress: LevelProgress = getOrInsertProgress(id)
  progress.bestTime = some(time)

proc getBestTime*(id: Path): Option[Seconds] =
  if saveSlot.progress.hasKey(id):
    result = saveSlot.progress[id].bestTime
  else:
    result = none(Seconds)

proc setHasCollectedStar*(id: Path) =
  var progress: LevelProgress = getOrInsertProgress(id)
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
  saveSlot.saveJson(filePath)

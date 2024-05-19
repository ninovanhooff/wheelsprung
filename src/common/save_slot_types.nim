import options
import common/shared_types
import tables

## Models
type 
  LevelProgress* = ref object of RootObj
    levelId*: Path
    bestTime*: Option[Milliseconds]
    hasCollectedStar*: bool
  
  SaveSlot* = ref object of RootObj
    progress*: Table[Path, LevelProgress]
    modelVersion*: int

## Entities
type 
  LevelProgressEntity* = ref object of RootObj
    levelId*: Path
    bestTime*: Option[Milliseconds]
    hasCollectedStar*: bool
  
  SaveSlotEntity* = ref object of RootObj
    # Because of trouble serializing Tables, we use a sequence.
    # Since the table keys are the paths, the table can be reconstructed
    progress*: seq[LevelProgressEntity]
    modelVersion*: int

proc saveSlotToEntity*(slot: SaveSlot): SaveSlotEntity =
  result = SaveSlotEntity(progress: @[], modelVersion: slot.modelVersion)
  for level in slot.progress.values:
    result.progress.add(LevelProgressEntity(levelId: level.levelId, bestTime: level.bestTime, hasCollectedStar: level.hasCollectedStar))

proc saveSlotFromEntity*(entity: SaveSlotEntity): SaveSlot =
  var slot = SaveSlot(progress: initTable[Path, LevelProgress](), modelVersion: entity.modelVersion)
  for level in entity.progress:
    slot.progress[level.levelId] = LevelProgress(levelId: level.levelId, bestTime: level.bestTime, hasCollectedStar: level.hasCollectedStar)
  result = slot

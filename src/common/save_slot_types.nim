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
    lastOpenedLevel*: Option[string]
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
    # Note that this problem might have been resolved in the meantime
    progress*: seq[LevelProgressEntity]
    lastOpenedLevel*: Option[string]
    modelVersion*: int


proc newLevelProgress*(levelId: Path, bestTime: Option[Milliseconds], hasCollectedStar: bool): LevelProgress =
  return LevelProgress(levelId: levelId, bestTime: bestTime, hasCollectedStar: hasCollectedStar)

proc saveSlotToEntity*(slot: SaveSlot): SaveSlotEntity =
  result = SaveSlotEntity(
    progress: @[],
    lastOpenedLevel: slot.lastOpenedLevel, 
    modelVersion: slot.modelVersion
  )
  for level in slot.progress.values:
    result.progress.add(LevelProgressEntity(levelId: level.levelId, bestTime: level.bestTime, hasCollectedStar: level.hasCollectedStar))

proc saveSlotFromEntity*(entity: SaveSlotEntity): SaveSlot =
  var slot = SaveSlot(
    progress: initTable[Path, LevelProgress](),
    lastOpenedLevel: entity.lastOpenedLevel,
    modelVersion: entity.modelVersion
  )
  for level in entity.progress:
    slot.progress[level.levelId] = newLevelProgress(levelId = level.levelId, bestTime = level.bestTime, hasCollectedStar = level.hasCollectedStar)
  result = slot

proc copy*(progress: LevelProgress): LevelProgress =
  return newLevelProgress(levelId = progress.levelId, bestTime = progress.bestTime, hasCollectedStar = progress.hasCollectedStar)

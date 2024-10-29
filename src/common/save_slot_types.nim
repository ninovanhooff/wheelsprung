import options
import common/shared_types
import screens/screen_types
import tables

## Models
type 
  RestoreState* = seq[ScreenRestoreState]

  SaveSlot* = ref object of RootObj
    progress*: Table[Path, LevelProgress]
    lastOpenedLevel*: Option[string] # todo remove
    restoreState*: Option[RestoreState]
    playerName*: Option[string]
    modelVersion*: int
    # when adding a new field, add it to the entity as well
    # when modifying a field, increment modelVersion

## Entities
type 
  LevelProgressEntity* = ref object of RootObj
    levelId*: Path
    bestTime*: Option[Milliseconds]
    hasCollectedStar*: bool
    signature*: Option[string]

  SaveSlotEntity* = ref object of RootObj
    # Because of trouble serializing Tables, we use a sequence.
    # Since the table keys are the paths, the table can be reconstructed
    # Note that this problem might have been resolved in the meantime
    progress*: seq[LevelProgressEntity]
    lastOpenedLevel*: Option[string]
    restoreState*: Option[RestoreState]
    playerName*: Option[string]
    modelVersion*: int


proc newLevelProgress*(levelId: Path, bestTime: Option[Milliseconds], hasCollectedStar: bool, signature: Option[string]): LevelProgress =
  return LevelProgress(levelId: levelId, bestTime: bestTime, hasCollectedStar: hasCollectedStar, signature: signature)

proc saveSlotToEntity*(slot: SaveSlot): SaveSlotEntity =
  result = SaveSlotEntity(
    progress: @[],
    lastOpenedLevel: slot.lastOpenedLevel,
    restoreState: slot.restoreState,
    playerName: slot.playerName,
    modelVersion: slot.modelVersion
  )
  for level in slot.progress.values:
    result.progress.add(LevelProgressEntity(
      levelId: level.levelId,
      bestTime: level.bestTime,
      hasCollectedStar: level.hasCollectedStar,
      signature: level.signature
    ))

proc saveSlotFromEntity*(entity: SaveSlotEntity): SaveSlot =
  var slot = SaveSlot(
    progress: initTable[Path, LevelProgress](),
    lastOpenedLevel: entity.lastOpenedLevel,
    restoreState: entity.restoreState,
    playerName: entity.playerName,
    modelVersion: entity.modelVersion
  )
  for level in entity.progress:
    slot.progress[level.levelId] = newLevelProgress(
      levelId = level.levelId,
      bestTime = level.bestTime,
      hasCollectedStar = level.hasCollectedStar,
      signature = level.signature
    )
  result = slot

proc copy*(progress: LevelProgress): LevelProgress =
  return newLevelProgress(levelId = progress.levelId, bestTime = progress.bestTime, hasCollectedStar = progress.hasCollectedStar, signature = progress.signature)

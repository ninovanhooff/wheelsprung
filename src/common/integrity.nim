import sha3
import options
import common/save_slot_types
import common/shared_types

const LevelSalt* {.strdefine.}: string = "NO_SALT"
const GameResultSalt* {.strdefine.}: string = "NO_SALT"


proc calculateHash(progress: LevelProgress): string =
  if progress.bestTime.isNone:
    return ""

  let bestTime = $progress.bestTime.get()
  let hasCollectedStar = $progress.hasCollectedStar
  return getSHA3(
    progress.levelId & bestTime & hasCollectedStar & GameResultSalt
  )

proc sign*(progress: LevelProgress) =
  if progress.bestTime.isNone:
    return

  progress.signature = some(progress.calculateHash())

proc verify*(progress: LevelProgress, levelId: Path): bool =
  ## levelId should not be taken from the progress object
  
  # This check is necessary to prevent and authentic signature from being used for another level
  if levelId != progress.levelId: return false
  if progress.bestTime.isNone: return false

  let signature = progress.calculateHash()
  return progress.signature == some(signature)

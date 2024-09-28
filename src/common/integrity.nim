import options
import strutils
import common/save_slot_types
import common/shared_types
import murmurhash

const LevelSalt {.strdefine.}: string = "NO_LEVEL_SALT" # Replaced by actual value in config.nims
const GameResultSalt {.strdefine.}: string = "NO_GAME_RESULT_SALT"

proc murmurHash(s: string): string =
  let arr = MurmurHash3_x64_128(s)
  return arr[1].toHex & arr[0].toHex

proc levelContentHash*(levelContent:string): string =
  return murmurHash(levelContent & LevelSalt)

proc calculateHash(progress: LevelProgress): string =
  if progress.bestTime.isNone:
    return ""

  let bestTime = $progress.bestTime.get()
  let hasCollectedStar = $progress.hasCollectedStar
  return murmurHash(
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

import common/integrity
import level_meta/level_data
import std/strutils
import tables

const relativeLevelDataPath = "../src/level_meta/level_data.nim"

proc updateHash(oldHash: string, newHash: string) =
  try:
    var fileContent = readFile(relativeLevelDataPath)
    fileContent = fileContent.replace(oldHash, newHash)
    writeFile(relativeLevelDataPath, fileContent)
  except:
    echo "Failed to update file: ", getCurrentExceptionMsg()

proc testPath(path: string) =
  try:
    let jsonString = readFile(path)
    let oneLinerResult = jsonString.levelContentHash()
    let expectedHash = officialLevels[path].contentHash
    if oneLinerResult != expectedHash:
      echo "updating: ", path, " expected: ", expectedHash, " got: ", oneLinerResult
      updateHash(expectedHash, oneLinerResult)
    else:
      echo "up to date: ", path
  except:
    echo "Failed to load file: ", getCurrentExceptionMsg()

proc updateHashes() =
  echo "===== Updating Level Hashes ====="
  for k in officialLevels.keys:
    testPath(k)

  echo "====== End Updating level Hashes ======"

when isMainModule:
  updateHashes()


import flatty
import common/integrity
import level_meta/level_data
import level_meta/level_entity
import std/paths
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
    let actualHash = jsonString.levelContentHash()
    let expectedHash = officialLevels[path].contentHash
    if actualHash != expectedHash:
      echo "updating: ", path, " expected: ", expectedHash, " got: ", actualHash
      updateHash(expectedHash, actualHash)

      # update Flatty file
      let levelEntity = parseJsonLevelContents(jsonString)
      let flattyString = levelEntity.toFlatty()
      let flattyPath = Path(path).changeFileExt("flatty")
      writeFile(flattyPath.string, flattyString)
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


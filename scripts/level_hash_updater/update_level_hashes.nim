import flatty
import common/integrity
import level_meta/level_data
import level_meta/level_entity
import std/paths
import std/strutils
import tables

const relativeLevelDataPath = "./src/level_meta/level_data.nim"
const relativeSourcePath = "./Source"

proc updateHash(oldHash: string, newHash: string) =
  try:
    var fileContent = readFile(relativeLevelDataPath)
    fileContent = fileContent.replace(oldHash, newHash)
    writeFile(relativeLevelDataPath, fileContent)
  except:
    echo "Failed to update file: ", getCurrentExceptionMsg()

proc testPath(path: string) =
  try:
    let fullPath = (Path(relativeSourcePath) / Path(path)).string
    let jsonString = readFile(fullPath)
    let actualHash = jsonString.levelContentHash()
    let expectedHash = officialLevels[path].contentHash
    if actualHash != expectedHash:
      echo "updating: ", path, " expected: ", expectedHash, " got: ", actualHash
      try:
        updateHash(expectedHash, actualHash)
      except:
        echo "Failed to update hash for ", path, getCurrentExceptionMsg()

      # update Flatty file
      let levelEntity = parseJsonLevelContents(jsonString)
      let flattyString = levelEntity.toFlatty()
      let flattyPath = Path(fullPath).changeFileExt("flatty")
      writeFile(flattyPath.string, flattyString)
    else:
      echo "up to date: ", path
  except:
    echo "Failed to process file: ", getCurrentExceptionMsg()

proc updateHashes() =
  echo "===== Updating Level Hashes ====="
  for k in officialLevels.keys:
    testPath(k)

  echo "====== End Updating level Hashes ======"

when isMainModule:
  updateHashes()


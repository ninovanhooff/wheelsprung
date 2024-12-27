import flatty
import common/integrity
import level_meta/level_data
import level_meta/level_entity
import std/dirs
import std/paths
import std/strutils
import tables

const relativeLevelDataPath = "./src/level_meta/level_data.nim"
const relativeSourcePath = "./Source"
const relativeSupportLevelsPath = "./support/levels"

proc convertLevels() =
  echo "===== Converting Levels ====="
  for entry in walkDir(Path(relativeSupportLevelsPath)):
    let path = entry.path
    let fullPath = path.string
    let splitFile = path.splitFile
    if splitFile.ext == jsonLevelFileExtensionWithDot:
      # update Flatty file
      try:
        let jsonString = readFile(fullPath)
        let levelEntity = parseJsonLevelContents(jsonString)
        let flattyString = levelEntity.toFlatty()
        let flattyPath = Path(fullPath.replace("support", "Source")).changeFileExt(flattyLevelFileExtension)
        writeFile(flattyPath.string, flattyString)
      except:
        echo "Failed to convert file: ", getCurrentExceptionMsg()

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
  convertLevels()
  updateHashes()


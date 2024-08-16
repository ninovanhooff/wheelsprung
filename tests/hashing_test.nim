import sha3
import common/utils
import level_meta/level_data
import playdate/api
import tables

import minitest

proc testPath(path: string) =
  try:
    let jsonString = playdate.file.open(path, kFileRead).readString()
    let oneLinerResult = getSHA3(jsonString)
    print fmt"Hash for {path} is: {oneLinerResult}"
    let expectedHash = officialLevels[path].contentHash
    check expectedHash, oneLinerResult
  except:
    print "Failed to load file", getCurrentExceptionMsg()

proc testHashing*() =
  print "===== Testing Hashing ====="
  for k in officialLevels.keys:
    testPath(k)

  print "====== End Hashing ======"


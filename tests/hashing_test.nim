import common/utils
import common/integrity
import level_meta/level_data
import playdate/api
import tables

import minitest

proc testPath(path: string) =
  try:
    let jsonString = playdate.file.open(path, kFileRead).readString()
    let oneLinerResult = jsonString.levelContentHash()
    let expectedHash = officialLevels[path].contentHash
    check(expected = expectedHash, actual = oneLinerResult, failureMsg = fmt"{path} FAILED")
  except:
    print "Failed to load file", getCurrentExceptionMsg()

proc testHashing*() =
  print "===== Testing Hashing ====="
  for k in officialLevels.keys:
    testPath(k)

  print "====== End Hashing ======"


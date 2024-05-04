import playdate/api
import marshal
import utils
import options
import tables

let kFileReadAny*: FileOptions = cast[FileOptions]({kFileRead, kFileReadData})

proc saveJson*[T](value: T, path: string) {.raises:[].} =
  try:
    let jsonNode = $$value
    let jsonString = $jsonNode
    let bytes: seq[byte] = cast[seq[byte]](jsonString)
    let file = playdate.file.open(path, kFileWrite)
    let lenWritten = file.write(bytes, bytes.len.uint32)
    if lenWritten != bytes.len:
      print "Failed to write file", path, "wrote", lenWritten, "bytes out of", bytes.len, "bytes"
    # no need to close file as Playdate API will do it for us
  except:
    print "Failed to save file", path, getCurrentExceptionMsg()

proc loadJson*[T](path: string, fileOptions: FileOptions = kFileReadAny): Option[T] {.raises:[].} =
  try:
    let jsonString = playdate.file.open(path, fileOptions).readString()
    let value = to[T](jsonString)
    # no need to close file as Playdate API will do it for us
    return some(value)
  except:
    print "Failed to load file", path, getCurrentExceptionMsg()
    return none(T)

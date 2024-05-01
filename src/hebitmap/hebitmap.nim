{.push raises: [].}
import std/importutils

import playdate/api

type HEBitmapPtr* = pointer

type HEBitmapObj* = object of RootObj
  # lcdBitmapPtr {.requiresInit.}: LCDBitmapPtr
  resource {.requiresInit.}: HEBitmapPtr
  free: bool

type HEBitmap* = ref HEBitmapObj

type ConstChar {.importc: "const char*".} = cstring
# type ConstCharPtr {.importc: "const char**".} = cstring
# type Char {.importc: "char*".} = cstring

type LCDBitmapPtr* {.importc: "LCDBitmap*", header: "pd_api.h".} = pointer

proc heBitmapSetPlaydateAPI*(api: ptr PlaydateAPI) {.importc: "HEBitmapSetPlaydateAPI", cdecl.}
proc privateHeBitmapNew*(lcdBitmap: pointer): HEBitmapPtr {.importc: "HEBitmapNew", cdecl.}

proc newHeBitmap*(this: ptr PlaydateGraphics, path: string): HEBitmap {.raises: [IOError]} =
    privateAccess(PlaydateGraphics)
    var err: ConstChar = nil
    var lcdBitmapPtr = this.loadBitmap(path, addr(err))
    var heBitmapPtr = privateHeBitmapNew(lcdBitmapPtr)
    let heBitmap = HEBitmap(resource: heBitmapPtr, free: true)
    if heBitmap.resource == nil:
        raise newException(IOError, $err)
    return heBitmap
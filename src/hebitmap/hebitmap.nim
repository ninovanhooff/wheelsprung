{.push raises: [].}
import std/importutils

import playdate/api {.all}
import utils

type HEBitmapPtr* = pointer
proc privateHeBitmapFree*(heBitmap: HEBitmapPtr) {.importc: "HEBitmapFree", cdecl.}

type HEBitmapObj* = object of RootObj
  resource {.requiresInit.}: HEBitmapPtr
  free: bool
proc `=destroy`(this: var HEBitmapObj) =
    if this.free:
        privateHeBitmapFree(this.resource)
type HEBitmap* = ref HEBitmapObj

type ConstChar {.importc: "const char*".} = cstring

# type LCDBitmapPtr* {.importc: "LCDBitmap*", header: "pd_api.h".} = pointer

proc heBitmapSetPlaydateAPI*(api: ptr PlaydateAPI) {.importc: "HEBitmapSetPlaydateAPI", cdecl.}

proc privateHeBitmapNew*(lcdBitmap: pointer): HEBitmapPtr {.importc: "HEBitmapNew", cdecl.}
proc newHeBitmap*(this: ptr PlaydateGraphics, path: string): HEBitmap {.raises: [IOError]} =
    privateAccess(PlaydateGraphics)
    var err: ConstChar = nil
    var lcdBitmapPtr = this.loadBitmap(path, addr(err))
    var heBitmapPtr = privateHeBitmapNew(lcdBitmapPtr)
    let heBitmap = HEBitmap(resource: heBitmapPtr, free: true)
    this.freeBitmap(lcdBitmapPtr)
    if heBitmap.resource == nil:
        raise newException(IOError, $err)
    return heBitmap

proc newHeBitmap*(lcdBitmap: LCDbitmap): HEBitmap =
    privateAccess(LCDBitmap)
    var heBitmapPtr = privateHeBitmapNew(lcdBitmap.resource)
    let heBitmap = HEBitmap(resource: heBitmapPtr, free: true)
    return heBitmap

proc privateHeBitmapDraw*(heBitmap: HEBitmapPtr, x: cint, y: cint) {.importc: "HEBitmapDraw", cdecl.}
proc draw*(this: HEBitmap, x: int, y: int) =
    if this.resource == nil:
        print "HEBitmap resource is nil"
        return
    privateHeBitmapDraw(this.resource, x.cint, y.cint)
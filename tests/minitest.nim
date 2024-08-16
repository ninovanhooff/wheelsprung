import strformat, strutils, macros

## Inspired by https://github.com/xmonader/nim-minitest
template check*(exp:untyped, expected: untyped = true, failureMsg:string="FAILED", indent:uint=0): void =
  let indentationStr = repeat(' ', indent)
  let expStr: string = astToStr(exp)
  var msg: string
  if exp != expected:
    msg = indentationStr & expStr & " .. " & failureMsg & "\n (expected: " & astToStr(expected) & ", actual: " & $exp & ")"
  else:
    msg = indentationStr & expStr & " .. passed"

  print(msg)
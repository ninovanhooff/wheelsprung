import strformat, strutils, macros

## Inspired by https://github.com/xmonader/nim-minitest
template check*(actual:untyped, expected: untyped = true, failureMsg:string="FAILED", indent:uint=0, printSuccesses=false): void =
  let indentationStr = repeat(' ', indent)
  let expStr: string = astToStr(actual)
  var msg: string
  if actual != expected:
    var expectedRepr = astToStr(expected)
    if expectedRepr != repr(expected):
      expectedRepr = $expectedRepr & "(" & $expected & ")"
    msg = indentationStr & expStr & " .. " & failureMsg & "\n (expected: " & expectedRepr & ", actual: " & $actual & ")"
    print(msg)
  elif printSuccesses:
    msg = indentationStr & expStr & " .. passed"
    print(msg)
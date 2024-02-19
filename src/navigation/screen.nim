import utils

type Screen* = ref object of RootObj

method init*(screen: Screen) {.base, locks:0, raises: [].} =
  discard

method resume*(screen: Screen) {.base, locks:0, raises: [].} =
  discard

method update*(self: Screen): int {.base, locks:0, raises: [].} =
  print "Screen.update not implemented"
  return 0
##[ returns 0 if no screen update is needed or 1 if there is.
  ]##    
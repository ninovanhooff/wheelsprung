{.push base, locks:0, raises: [].}
import utils

type Screen* = ref object of RootObj

method `$`*(self: Screen): string = "'$' not implemented for this screen"

method init*(screen: Screen) =
  discard

method pause*(screen: Screen) =
  discard

method resume*(screen: Screen) =
  discard

method destroy*(screen: Screen) =
  discard

method update*(self: Screen): int =
  ##[ returns 0 if no screen update is needed or 1 if there is.
  ]##
  print "update not implemented for screen: " & $self
  return 0

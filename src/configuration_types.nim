import options

type DPadInputType* {.pure.} = enum
  # value is json-serialised value and must not be changed
  Jolt = "jolt", Constant = "constant", Gradual = "gradual"

type Config* = ref object of RootObj
  lastOpenedLevel*: Option[string]
  dPadInputType*: Option[DPadInputType]


proc `$`*(inputType: DPadInputType): string =
  ## Display value for Settings screen
  case inputType
  of DPadInputType.Jolt: return "Jolt"
  of DPadInputType.Constant: return "Constant"
  of DPadInputType.Gradual: return "Gradual"
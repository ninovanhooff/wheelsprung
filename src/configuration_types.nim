import options
import shared_types

type Config* = ref object of RootObj
  lastOpenedLevel*: Option[string]
  dPadInputType*: Option[DPadInputType]
  dPadInputMultiplier*: Option[float]


proc `$`*(inputType: DPadInputType): string =
  ## Display value for Settings screen
  case inputType
  of DPadInputType.Jolt: return "Jolt"
  of DPadInputType.Constant: return "Constant"
  of DPadInputType.Parabolic: return "Parabolic"
  of DPadInputType.Sinical: return "Sine"
  of DPadInputType.EaseOutBack: return "Ease Out Back"
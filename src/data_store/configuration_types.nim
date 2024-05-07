import options
import common/shared_types

type Config* = ref object of RootObj
  lastOpenedLevel*: Option[string]
  tiltAttitudeAdjustEnabled*: Option[bool]
  dPadInputType*: Option[DPadInputType]
  dPadInputMultiplier*: Option[float]

proc displayName*(enabled: bool): string =
  if enabled: 
    return "Enabled"
  else: 
    return "Disabled"

proc displayName*(inputType: DPadInputType): string =
  ## Display value for Settings screen
  case inputType
  of DPadInputType.Constant: return "Constant"
  of DPadInputType.Linear: return "Linear"
  of DPadInputType.Parabolic: return "Parabolic"
  of DPadInputType.Sinical: return "Sine"
  of DPadInputType.EaseOutBack: return "Ease Out Back"
  of DPadInputType.Jolt: return "Jolt"

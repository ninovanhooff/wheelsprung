{.push raises: [].}
import screens/game/game_types
import playdate/api
import common/utils

proc addInputFrame*(recording: InputRecording, currentButtons: PDButtons, idx: int32) =
  if recording.buttons.len == idx:
    recording.buttons.add(currentButtons)
  else:
    print fmt"ERROR: addInputFrame called with idx {idx} but recording has {recording.buttons.len} frames"


method getButtonState*(provider: InputProvider, frameIdx: int32): PDButtonState {.base.} =
  print fmt"ERROR: getButtonState not implemented for {provider.repr}"
  return default(PDButtonState)

method getButtonState*(provider: RecordedInputProvider, frameIdx: int32): PDButtonState =
  let recording = provider.recording
  if frameIdx >= recording.buttons.len:
    return default(PDButtonState)
  let current = recording.buttons[frameIdx]
  let previousOrEmpty = if frameIdx > 0:
    recording.buttons[frameIdx - 1]
  else:
    default(PDButtons)
  
  return (
    current: current,
    pushed: current - previousOrEmpty,
    released: previousOrEmpty - current,
  )

method getButtonState*(provider: LiveInputProvider, frameIdx: int32): PDButtonState =
  return playdate.system.getButtonState()

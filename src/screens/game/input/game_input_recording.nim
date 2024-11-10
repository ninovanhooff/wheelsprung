{.push raises: [].}
import std/sets
import screens/game/game_types
import playdate/api
import common/utils

proc newInputRecording*(): InputRecording =
  return InputRecording(
    buttons: @[],
  )

proc addInputFrame*(recording: InputRecording, currentButtons: PDButtons) =
  recording.buttons.add(currentButtons)

proc newLiveInputProvider*(): LiveInputProvider =
  return LiveInputProvider()

method getButtonState*(provider: InputProvider, grameIdx: int32): PDButtonState {.base.} =
  print fmt"ERROR: getButtonState not implemented for {provider.repr}"
  return default(PDButtonState)

method getButtonState*(provider: RecordedInputProvider, frameIdx: int32): PDButtonState =
  let recording = provider.recording
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

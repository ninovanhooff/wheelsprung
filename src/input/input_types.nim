import playdate/api

type
  PDButtonState* = tuple[current: PDButtons, pushed: PDButtons, released: PDButtons]

  InputRecording* = ref object
    buttons*: seq[PDButtons]
      ## Button states for each frame, corresponds to playdate.system.getButtonState().current for each frame
  
  InputProvider* = ref object of RootObj
    # proc getButtonState(frameIdx: int32): PDButtonState {.raises: []}

  LiveInputProvider* = ref object of InputProvider
  RecordedInputProvider* = ref object of InputProvider
    recording*: InputRecording
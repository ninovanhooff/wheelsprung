{. push raises: [].}

import screens/screen_types

type
  DialogScreen* = ref object of Screen
    title*: string
    message*: string
    confirmButtonText*: string

proc newDialogScreen*(title, message, confirmButtonText: string): DialogScreen =
  DialogScreen(
    title: title, 
    message: message, 
    confirmButtonText: confirmButtonText,
    screenType: ScreenType.Dialog
  )

let
  mirrorInstructionDialogScreen*: DialogScreen = newDialogScreen(
    title = "Mirror Instruction",
    message = "Use a quality USB cable directly. To fix video glitches or garbled audio, use “Audio > Disable Audio” in Mirror.",
    confirmButtonText = "OK"
  )

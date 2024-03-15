{.experimental: "codeReordering".}
{.push raises: [].}

import playdate/api
import navigation/screen
import configuration
import graphics_utils

const borderInset = 8
const contentY = 24

type
  Editor = ref object of RootObj
    label: string
    incrementor: proc (config: Config)
    decrementor: proc (config: Config)
    draw: proc (self: Editor, x: int, y: int, selected: bool)
  
  SettingsScreen = ref object of Screen
    configuration: Config
    editors: seq[Editor]
    selectedIdx: int

proc drawLabel*(editor: Editor, x: int, y: int) =
  gfx.drawText(editor.label, x, y)

let inputTypeEditor = Editor(
  label: "Input Type", 
  incrementor: proc (config: Config) = config.incDpadInputType(),
  decrementor: proc (config: Config) = config.decDpadInputType(), 
  draw: proc (editor: Editor, x: int, y: int, selected: bool) = drawLabel(editor, x, y)
)

proc increaseValue*(self: SettingsScreen) =
  self.editors[self.selectedIdx].incrementor(self.configuration)

proc decreaseValue*(self: SettingsScreen) =
  discard

proc newSettingsScreen*(): SettingsScreen =
  return SettingsScreen()



proc updateInput*(screen: SettingsScreen) =
  let buttonState = playdate.system.getButtonsState()

  if kButtonA in buttonState.pushed:
    screen.increaseValue()
  elif kButtonB in buttonState.pushed:
    screen.decreaseValue()

proc draw*(screen: SettingsScreen) =
  var y = contentY
  for i, editor in screen.editors:
    editor.draw(editor, borderInset + 24, y, i == screen.selectedIdx)
    y += 20

## Screen methods

method resume*(screen: SettingsScreen) =
  {.warning[LockLevel]:off.}
  screen.configuration = getConfig()
  screen.editors = @[inputTypeEditor]
  screen.selectedIdx = 0
  

method update*(screen: SettingsScreen): int =
  {.warning[LockLevel]:off.}
  updateInput(screen)
  draw(screen)
  return 1

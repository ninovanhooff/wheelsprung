{.experimental: "codeReordering".}
{.push raises: [], warning[LockLevel]:off.}

import sugar, options
import playdate/api
import navigation/[navigator, screen]
import configuration_types, configuration
import graphics_types, graphics_utils
import editor, preview

const 
  borderInset = 8
  contentY = 24
  cellWidth = 400 - borderInset * 2
  cellHeight = 28

type
  SettingsScreen = ref object of Screen
    config: Config
    editors: seq[Editor]
    selectedIdx: int
    isInitialized: bool

let inputTypeEditor: Editor = Editor(
  label: "d-pad leaning", 
  incrementor: (config: Config) => config.incDpadInputType(),
  decrementor: (config: Config) => config.decDpadInputType(),
  value: (config: Config) => $config.getDPadInputType,
  preview: some[PreviewCallback](drawDPadInputResponsePreview),
)

let inputMultiplierEditor: Editor = Editor(
  label: "d-pad leaning multiplier", 
  incrementor: (config: Config) => config.incDpadInputMultiplier,
  decrementor: (config: Config) => config.decDpadInputMultiplier,
  value: (config: Config) => formatEditorFloat(config.getDPadInputMultiplier),
)

proc increaseValue*(self: SettingsScreen) =
  self.editors[self.selectedIdx].incrementor(self.config)

proc decreaseValue*(self: SettingsScreen) =
  self.editors[self.selectedIdx].decrementor(self.config)

proc newSettingsScreen*(): SettingsScreen =
  return SettingsScreen()



proc updateInput*(screen: SettingsScreen) =
  let buttonState = playdate.system.getButtonsState()

  if kButtonRight in buttonState.pushed or kButtonA in buttonState.pushed:
    screen.increaseValue()
  elif kButtonLeft in buttonState.pushed:
    screen.decreaseValue()
  elif kButtonUp in buttonState.pushed:
    screen.selectedIdx = max(0, screen.selectedIdx - 1)
  elif kButtonDown in buttonState.pushed:
    screen.selectedIdx = min(screen.selectedIdx + 1, screen.editors.high)
  elif kButtonB in buttonState.pushed:
    screen.config.save()
    popScreen()

proc draw*(screen: SettingsScreen) =
  gfx.clear(kColorWhite)

  let config = screen.config
  var y = contentY
  for i, editor in screen.editors:
    gfx.pushContext(nil)
    config.drawEditor(editor, borderInset, y, cellWidth, cellHeight, i == screen.selectedIdx)
    gfx.popContext()
    y += cellHeight

  let optPreview = screen.editors[screen.selectedIdx].preview
  if optPreview.isSome:
    let previewRect = Rect(x: 0,y: 140, width: 400, height:100)

    setScreenClipRect(previewRect)
    optPreview.get()(
      screen.config, previewRect
    )
    gfx.clearClipRect()

proc init(screen: SettingsScreen) =
  screen.editors = @[inputTypeEditor, inputMultiplierEditor]
  screen.selectedIdx = 0
  screen.isInitialized = true

## Screen methods

method pause*(screen: SettingsScreen) =
  screen.config.save()

method resume*(screen: SettingsScreen) =
  if not screen.isInitialized:
    screen.init()
  screen.config = getConfig()

method update*(screen: SettingsScreen): int =
  updateInput(screen)
  draw(screen)
  return 1

method `$`*(screen: SettingsScreen): string =
  return "SettingsScreen"

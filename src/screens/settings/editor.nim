{.push raises: [].}

import sugar
import strformat
import playdate/api
import graphics_utils
import configuration_types

const cellPadding = 8

type
  Editor* = ref object of RootObj
    label*: string
    incrementor*: (config: Config) -> void
    decrementor*: (config: Config) -> void
    draw*: (self: Editor, x: int, y: int, selected: bool) -> void
    value*: (config: Config) -> string

proc formatEditorFloat*(value: SomeFloat): string {.raises: [], tags: [].} =
  try:
    fmt"{value:.1f}"
  except: "cannot format value as float: " & value.repr

proc drawLabel(editor: Editor, x: int, y: int) =
  gfx.drawText(editor.label, x, y)

proc drawEditor*(config: Config, editor: Editor, x, y ,w, h: int, selected: bool) =
  if selected:
    gfx.fillRect(x, y, w, h, kColorBlack)
    gfx.setDrawMode(kDrawModeFillWhite)
  let textY = y + 3
  drawLabel(editor, x + cellPadding, textY)
  gfx.drawTextAligned(editor.value(config), x + w - cellPadding, textY, kTextAlignmentRight)
  
